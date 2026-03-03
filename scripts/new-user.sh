#!/usr/bin/env bash
set -euo pipefail

user="${1:-}"

if [[ -z "${user}" ]]; then
  echo "usage: scripts/new-user.sh <user>" >&2
  exit 1
fi

if [[ ! "${user}" =~ ^[a-z][a-z0-9]*$ ]]; then
  echo "error: user must match ^[a-z][a-z0-9]*$" >&2
  exit 1
fi

user_module_name="${user^}"
nixos_user_file="modules/nixosModules/users/${user}.nix"
hm_user_file="modules/homeModules/users/${user}.nix"

if [[ -e "${nixos_user_file}" || -e "${hm_user_file}" ]]; then
  echo "error: user '${user}' already exists (one or more target files already present)" >&2
  exit 1
fi

mkdir -p "$(dirname "${nixos_user_file}")" "$(dirname "${hm_user_file}")"

cat >"${nixos_user_file}" <<EOF_USER_NIXOS
{
  flake.nixosModules.user${user_module_name} = {
    # HM-first exception: users/groups are system-level declarations.
    users.users.${user} = {
      isNormalUser = true;
      group = "${user}";
      extraGroups = ["wheel"];
    };

    users.groups.${user} = {};
  };
}
EOF_USER_NIXOS

cat >"${hm_user_file}" <<EOF_USER_HM
{
  flake.homeModules.user${user_module_name} = {
    imports = [(import ../../../home/shell/fish-env.nix)];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
EOF_USER_HM

echo "created ${nixos_user_file}"
echo "created ${hm_user_file}"
