#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: just new-host host=<host> user=<user> [sops_key_path=<path>]
EOF
}

host="${1:-}"
user="${2:-}"
sops_key_path="${3:-}"

if [[ -z "${host}" || -z "${user}" ]]; then
  usage
  exit 1
fi

if [[ $# -gt 3 ]]; then
  echo "error: too many arguments" >&2
  usage
  exit 1
fi

if [[ ! "${host}" =~ ^[a-z][a-z0-9]*$ ]]; then
  echo "error: host must match ^[a-z][a-z0-9]*$" >&2
  exit 1
fi

if [[ ! "${user}" =~ ^[a-z][a-z0-9]*$ ]]; then
  echo "error: user must match ^[a-z][a-z0-9]*$" >&2
  exit 1
fi

host_module_name="${host^}"
user_module_name="${user^}"

nixos_user_file="modules/nixosModules/users/${user}.nix"
hm_user_file="modules/homeModules/users/${user}.nix"

if [[ ! -f "${nixos_user_file}" && ! -f "${hm_user_file}" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  echo "user '${user}' not found; scaffolding user first"
  bash "${script_dir}/new-user.sh" "${user}" "${sops_key_path}"
elif [[ ! -f "${nixos_user_file}" || ! -f "${hm_user_file}" ]]; then
  echo "error: user '${user}' is in a partial state" >&2
  echo "expected both files:" >&2
  echo "  - ${nixos_user_file}" >&2
  echo "  - ${hm_user_file}" >&2
  exit 1
fi

host_dir="modules/nixosModules/hosts/${host}"
config_file="${host_dir}/configuration.nix"
hardware_file="${host_dir}/hardware-configuration.nix"

if [[ -e "${config_file}" || -e "${hardware_file}" ]]; then
  echo "error: host '${host}' already exists (one or more target files already present)" >&2
  exit 1
fi

mkdir -p "${host_dir}"

config_tmp="$(mktemp)"
hardware_tmp="$(mktemp)"
trap 'rm -f "${config_tmp}" "${hardware_tmp}"' EXIT

cat >"${config_tmp}" <<EOF_HOST_CONFIG
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.${host} = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.host${host_module_name}];
  };

  flake.nixosModules.host${host_module_name} = {
    lib,
    ...
  }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops

      self.nixosModules.base
      self.nixosModules.user${user_module_name}
    ];

    networking.hostName = "${host}";
    system.stateVersion = "25.11";

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${user} = {
      imports = [self.homeModules.user${user_module_name}];
      home.username = lib.mkDefault "${user}";
      home.homeDirectory = lib.mkDefault "/home/${user}";
    };

    # HM-first exception: secret format selection is host-level secret plumbing.
    sops.defaultSopsFormat = "yaml";
  };
}
EOF_HOST_CONFIG

cat >"${hardware_tmp}" <<EOF_HOST_HW
{
  flake.nixosModules.host${host_module_name} = {lib, ...}: {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
EOF_HOST_HW

mv "${config_tmp}" "${config_file}"
mv "${hardware_tmp}" "${hardware_file}"
trap - EXIT

echo "created ${config_file}"
echo "created ${hardware_file}"
