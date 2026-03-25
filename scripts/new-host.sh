#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: just new-host host=<host> user=<user>
EOF
}

render_host_template() {
  local template_path="$1"
  local output_path="$2"
  local host_name="$3"
  local host_module_name="$4"
  local user_name="$5"
  local user_module_name="$6"

  sed \
    -e "s/__HOST__/${host_name}/g" \
    -e "s/__HOST_CAP__/${host_module_name}/g" \
    -e "s/__USER__/${user_name}/g" \
    -e "s/__USER_CAP__/${user_module_name}/g" \
    "${template_path}" > "${output_path}"
}

host="${1:-}"
user="${2:-}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${host}" || -z "${user}" ]]; then
  usage
  exit 1
fi

if [[ $# -gt 2 ]]; then
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
template_root="${script_dir}/templates/new-host"
config_template="${template_root}/configuration.nix.template"
hardware_template="${template_root}/hardware-configuration.nix.template"
niri_template_dir="${template_root}/niri"

nixos_user_file="modules/nixosModules/users/${user}.nix"
hm_user_profile_file="modules/homeModules/users/${user}/profile.nix"

if [[ ! -f "${nixos_user_file}" && ! -f "${hm_user_profile_file}" ]]; then
  echo "user '${user}' not found; scaffolding user first"
  bash "${script_dir}/new-user.sh" "${user}"
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
user_host_configs_dir="configs/users/${user}/hosts/${host}"
user_host_niri_dir="${user_host_configs_dir}/niri"

if [[ -e "${config_file}" || -e "${hardware_file}" || -e "${user_host_configs_dir}" ]]; then
  echo "error: host '${host}' already exists (one or more target files already present)" >&2
  exit 1
fi

if [[ ! -f "${config_template}" || ! -f "${hardware_template}" || ! -d "${niri_template_dir}" ]]; then
  echo "error: expected host scaffold templates are missing" >&2
  echo "required sources:" >&2
  echo "  - ${config_template}" >&2
  echo "  - ${hardware_template}" >&2
  echo "  - ${niri_template_dir}/" >&2
  exit 1
fi

mkdir -p "${host_dir}" "${user_host_niri_dir}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

config_tmp="${tmp_dir}/configuration.nix"
hardware_tmp="${tmp_dir}/hardware-configuration.nix"

render_host_template "${config_template}" "${config_tmp}" "${host}" "${host_module_name}" "${user}" "${user_module_name}"
render_host_template "${hardware_template}" "${hardware_tmp}" "${host}" "${host_module_name}" "${user}" "${user_module_name}"

mv "${config_tmp}" "${config_file}"
mv "${hardware_tmp}" "${hardware_file}"
cp -R "${niri_template_dir}/." "${user_host_niri_dir}/"

echo "created ${config_file}"
echo "created ${hardware_file}"
echo "created ${user_host_configs_dir}/"
echo "warning: ${hardware_file} is a placeholder; replace it with host-specific hardware before running just check or just check-vm"
