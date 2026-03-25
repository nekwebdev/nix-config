#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: just new-user user=<user>
EOF
}

render_user_template() {
  local template_path="$1"
  local output_path="$2"
  local user_name="$3"
  local user_module_name="$4"

  sed \
    -e "s/__USER__/${user_name}/g" \
    -e "s/__USER_CAP__/${user_module_name}/g" \
    "${template_path}" > "${output_path}"
}

user="${1:-}"
shift || true
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${user}" ]]; then
  usage
  exit 1
fi

if [[ $# -gt 0 ]]; then
  echo "error: too many arguments" >&2
  usage
  exit 1
fi

if [[ ! "${user}" =~ ^[a-z][a-z0-9]*$ ]]; then
  echo "error: user must match ^[a-z][a-z0-9]*$" >&2
  exit 1
fi

user_module_name="${user^}"
nixos_user_file="modules/nixosModules/users/${user}.nix"
hm_user_dir="modules/homeModules/users/${user}"
hm_user_base_file="${hm_user_dir}/base.nix"
hm_user_profile_file="${hm_user_dir}/profile.nix"
user_configs_dir="configs/users/${user}"
user_common_configs_dir="${user_configs_dir}/common"
template_root="${script_dir}/templates/new-user"
nixos_user_template="${template_root}/user-module.nix.template"
hm_user_base_template="${template_root}/base.nix.template"
hm_user_profile_template="${template_root}/profile.nix.template"
common_configs_template_dir="${template_root}/common"

if [[ -e "${nixos_user_file}" || -e "${hm_user_dir}" || -e "${user_configs_dir}" ]]; then
  echo "error: user '${user}' already exists (one or more target files already present)" >&2
  exit 1
fi

if [[ ! -f "${nixos_user_template}" || ! -f "${hm_user_base_template}" || ! -f "${hm_user_profile_template}" || ! -d "${common_configs_template_dir}" ]]; then
  echo "error: expected user scaffold templates are missing" >&2
  echo "required sources:" >&2
  echo "  - ${nixos_user_template}" >&2
  echo "  - ${hm_user_base_template}" >&2
  echo "  - ${hm_user_profile_template}" >&2
  echo "  - ${common_configs_template_dir}/" >&2
  exit 1
fi

mkdir -p "$(dirname "${nixos_user_file}")" "${hm_user_dir}" "${user_common_configs_dir}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

render_user_template "${nixos_user_template}" "${tmp_dir}/user.nix" "${user}" "${user_module_name}"
render_user_template "${hm_user_base_template}" "${tmp_dir}/base.nix" "${user}" "${user_module_name}"
render_user_template "${hm_user_profile_template}" "${tmp_dir}/profile.nix" "${user}" "${user_module_name}"

mv "${tmp_dir}/user.nix" "${nixos_user_file}"
mv "${tmp_dir}/base.nix" "${hm_user_base_file}"
mv "${tmp_dir}/profile.nix" "${hm_user_profile_file}"
cp -R "${common_configs_template_dir}/." "${user_common_configs_dir}/"

echo "created ${nixos_user_file}"
echo "created ${hm_user_base_file}"
echo "created ${hm_user_profile_file}"
echo "created ${hm_user_dir}/"
echo "created ${user_common_configs_dir}/"
echo "next: edit ${hm_user_profile_file} to set git identity, packages, flatpaks, and session variables"
