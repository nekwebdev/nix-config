#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: just new-user user=<user>
EOF
}

replace_user_placeholders() {
  local file_path="$1"
  local user_name="$2"
  local user_module="$3"

  sed -i \
    -e "s/\\<oj\\>/${user_name}/g" \
    -e "s/ojNiri/${user_name}Niri/g" \
    -e "s/Oj/${user_module}/g" \
    "${file_path}"
}

user="${1:-}"
shift || true

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
hm_user_profile_file="${hm_user_dir}/niri.nix"
user_configs_dir="configs/users/${user}"
source_nixos_user_file="modules/nixosModules/users/oj.nix"
source_hm_user_dir="modules/homeModules/users/oj"
source_hm_user_profile_file="${source_hm_user_dir}/niri.nix"
source_user_configs_dir="configs/users/oj"

if [[ -e "${nixos_user_file}" || -e "${hm_user_dir}" || -e "${user_configs_dir}" ]]; then
  echo "error: user '${user}' already exists (one or more target files already present)" >&2
  exit 1
fi

if [[ ! -f "${source_nixos_user_file}" || ! -d "${source_hm_user_dir}" || ! -f "${source_hm_user_profile_file}" || ! -d "${source_user_configs_dir}" ]]; then
  echo "error: expected oj source modules are missing" >&2
  echo "required sources:" >&2
  echo "  - ${source_nixos_user_file}" >&2
  echo "  - ${source_hm_user_dir}/" >&2
  echo "  - ${source_hm_user_profile_file}" >&2
  echo "  - ${source_user_configs_dir}/" >&2
  exit 1
fi

mkdir -p "$(dirname "${nixos_user_file}")" "$(dirname "${hm_user_dir}")"

cp "${source_nixos_user_file}" "${nixos_user_file}"
cp -R "${source_hm_user_dir}" "${hm_user_dir}"
cp -R "${source_user_configs_dir}" "${user_configs_dir}"

replace_user_placeholders "${nixos_user_file}" "${user}" "${user_module_name}"

while IFS= read -r -d '' hm_fragment; do
  replace_user_placeholders "${hm_fragment}" "${user}" "${user_module_name}"
done < <(find "${hm_user_dir}" -type f -name '*.nix' -print0)

echo "created ${nixos_user_file}"
echo "created ${hm_user_profile_file}"
echo "created ${hm_user_dir}/"
echo "created ${user_configs_dir}/"
