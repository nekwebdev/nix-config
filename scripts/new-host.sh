#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: just new-host host=<host> user=<user> [sops_key_path=<path>]
EOF
}

extract_sops_user_key_path() {
  local user_module_file="$1"
  sed -nE 's/^[[:space:]]*sopsUserKeyPath[[:space:]]*=[[:space:]]*"([^"]+)";/\1/p' "${user_module_file}" | head -n1
}

replace_host_placeholders() {
  local file_path="$1"
  local host_name="$2"
  local host_module_name="$3"
  local user_name="$4"
  local user_module_name="$5"

  sed -i \
    -e "s/\\<lotus\\>/${host_name}/g" \
    -e "s/Lotus/${host_module_name}/g" \
    -e "s/\\<oj\\>/${user_name}/g" \
    -e "s/ojNiri/${user_name}Niri/g" \
    -e "s/Oj/${user_module_name}/g" \
    "${file_path}"
}

host="${1:-}"
user="${2:-}"
sops_key_path="${3:-}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
hm_user_profile_file="modules/homeModules/users/${user}/niri.nix"

if [[ ! -f "${nixos_user_file}" && ! -f "${hm_user_profile_file}" ]]; then
  echo "user '${user}' not found; scaffolding user first"
  bash "${script_dir}/new-user.sh" "${user}" "${sops_key_path}"
elif [[ ! -f "${nixos_user_file}" || ! -f "${hm_user_profile_file}" ]]; then
  echo "error: user '${user}' is in a partial state" >&2
  echo "expected both modules:" >&2
  echo "  - ${nixos_user_file}" >&2
  echo "  - ${hm_user_profile_file}" >&2
  exit 1
fi

host_dir="modules/nixosModules/hosts/${host}"
config_file="${host_dir}/configuration.nix"
hardware_file="${host_dir}/hardware-configuration.nix"
source_host_dir="modules/nixosModules/hosts/lotus"
source_config_file="${source_host_dir}/configuration.nix"
source_hardware_file="${source_host_dir}/hardware-configuration.nix"
user_host_configs_dir="configs/users/${user}/hosts/${host}"
source_user_lotus_configs_dir="configs/users/${user}/hosts/lotus"

if [[ -e "${config_file}" || -e "${hardware_file}" || -e "${user_host_configs_dir}" ]]; then
  echo "error: host '${host}' already exists (one or more target files already present)" >&2
  exit 1
fi

if [[ ! -f "${source_config_file}" || ! -f "${source_hardware_file}" ]]; then
  echo "error: expected lotus source host modules are missing" >&2
  echo "required sources:" >&2
  echo "  - ${source_config_file}" >&2
  echo "  - ${source_hardware_file}" >&2
  exit 1
fi

sops_user_key_path="$(extract_sops_user_key_path "${nixos_user_file}")"
if [[ -z "${sops_user_key_path}" ]]; then
  echo "error: unable to extract sopsUserKeyPath from ${nixos_user_file}" >&2
  exit 1
fi

mkdir -p "${host_dir}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

config_tmp="${tmp_dir}/configuration.nix"
hardware_tmp="${tmp_dir}/hardware-configuration.nix"

cp "${source_config_file}" "${config_tmp}"
cp "${source_hardware_file}" "${hardware_tmp}"

replace_host_placeholders "${config_tmp}" "${host}" "${host_module_name}" "${user}" "${user_module_name}"
replace_host_placeholders "${hardware_tmp}" "${host}" "${host_module_name}" "${user}" "${user_module_name}"

escaped_sops_user_key_path="$(printf '%s' "${sops_user_key_path}" | sed -e 's/[&|]/\\&/g')"
sed -i -E \
  "s|sopsUserSshKeyPath = \".*\";|sopsUserSshKeyPath = \"${escaped_sops_user_key_path}\";|" \
  "${config_tmp}"

mv "${config_tmp}" "${config_file}"
mv "${hardware_tmp}" "${hardware_file}"
trap - EXIT

if [[ -d "${source_user_lotus_configs_dir}" ]]; then
  mkdir -p "$(dirname "${user_host_configs_dir}")"
  cp -R "${source_user_lotus_configs_dir}" "${user_host_configs_dir}"
  echo "created ${user_host_configs_dir}/ (copied from ${source_user_lotus_configs_dir}/)"
else
  mkdir -p "${user_host_configs_dir}"
  echo "created ${user_host_configs_dir}/"
fi

echo "created ${config_file}"
echo "created ${hardware_file}"
