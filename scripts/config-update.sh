#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat >&2 <<'USAGE'
usage:
  config-update.sh [--dry-run|-n]

options:
  --dry-run, -n  Print git-style diffs for repo config files that would change.
USAGE
}

dry_run=0

case "${1:-}" in
  "")
    ;;
  --dry-run|-n)
    dry_run=1
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 1
    ;;
esac

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

map_found=0
if [[ "${dry_run}" -eq 1 ]]; then
  diff_output="$(mktemp)"
  trap 'rm -f "${diff_output}"' EXIT

  while IFS= read -r map_name; do
    if [[ -z "${map_name}" ]]; then
      continue
    fi

    map_found=1
    bash "${script_dir}/runtime-config-helper.sh" pull-diff "${map_name}" >>"${diff_output}"
  done < <(bash "${script_dir}/runtime-config-helper.sh" maps)

  if [[ "${map_found}" -eq 0 ]]; then
    echo "error: runtime-config-helper returned no sync maps" >&2
    exit 1
  fi

  if [[ -s "${diff_output}" ]]; then
    cat "${diff_output}"
  else
    echo "No runtime config changes would be applied."
  fi

  exit 0
fi

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
