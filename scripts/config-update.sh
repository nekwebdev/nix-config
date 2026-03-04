#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

map_found=0
while IFS= read -r map_name; do
  if [[ -z "${map_name}" ]]; then
    continue
  fi

  map_found=1
  bash "${script_dir}/runtime-config-helper.sh" pull "${map_name}"
done < <(bash "${script_dir}/runtime-config-helper.sh" maps)

if [[ "${map_found}" -eq 0 ]]; then
  echo "error: runtime-config-helper returned no sync maps" >&2
  exit 1
fi
