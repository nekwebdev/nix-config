#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
source_root="${repo_root}/configs"
target_root="${HOME}"

usage() {
  cat >&2 <<'USAGE'
usage:
  runtime-config-helper.sh maps
  runtime-config-helper.sh <seed|pull> <map_name>

operations:
  maps  Print available sync map names.
  seed  Copy config files from configs to HOME if target does not already exist.
  pull  Copy runtime config files from HOME back into configs.
USAGE
}

list_maps() {
  cat <<'MAPS'
dms
niri
zed
MAPS
}

list_sync_entries() {
  local map_name="$1"

  case "${map_name}" in
    dms)
      cat <<'ENTRIES'
# kind|source_rel|target_rel
# Source paths are relative to configs
# Target paths are relative to HOME

dir|dms|.config/DankMaterialShell
ENTRIES
      ;;
    niri)
      cat <<'ENTRIES'
# kind|source_rel|target_rel
# Source paths are relative to configs
# Target paths are relative to HOME

dir|niri|.config/niri/dms
ENTRIES
      ;;
    zed)
      cat <<'ENTRIES'
# kind|source_rel|target_rel
# Source paths are relative to configs
# Target paths are relative to HOME

file|zed/settings.json|.config/zed/settings.json
ENTRIES
      ;;
    *)
      echo "error: unknown sync map '${map_name}'" >&2
      exit 1
      ;;
  esac
}

copy_if_missing() {
  local src="$1"
  local dst="$2"

  if [[ ! -f "${src}" ]]; then
    echo "error: missing source file ${src}" >&2
    exit 1
  fi

  if [[ -e "${dst}" || -L "${dst}" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "${dst}")"
  install -m 0644 "${src}" "${dst}"
}

copy_back() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "${src}" && ! -L "${src}" ]]; then
    echo "skip: missing runtime file ${src}"
    return 0
  fi

  if [[ -L "${src}" && ! -e "${src}" ]]; then
    echo "skip: broken runtime symlink ${src}"
    return 0
  fi

  if [[ -e "${src}" && -e "${dst}" && "${src}" -ef "${dst}" ]]; then
    echo "skip: source already points at ${dst}"
    return 0
  fi

  cp --dereference "${src}" "${dst}"
  echo "updated ${dst}"
}

seed_entry() {
  local kind="$1"
  local source_rel="$2"
  local target_rel="$3"

  case "${kind}" in
    file)
      copy_if_missing "${source_root}/${source_rel}" "${target_root}/${target_rel}"
      ;;
    dir)
      local source_dir="${source_root}/${source_rel}"
      local target_dir="${target_root}/${target_rel}"
      local source_file rel_path target_file

      if [[ ! -d "${source_dir}" ]]; then
        echo "error: missing source directory ${source_dir}" >&2
        exit 1
      fi

      while IFS= read -r -d '' source_file; do
        rel_path="${source_file#${source_dir}/}"
        target_file="${target_dir}/${rel_path}"
        copy_if_missing "${source_file}" "${target_file}"
      done < <(find "${source_dir}" -type f -print0 | sort -z)
      ;;
    *)
      echo "error: unsupported sync entry kind '${kind}'" >&2
      exit 1
      ;;
  esac
}

pull_entry() {
  local kind="$1"
  local source_rel="$2"
  local target_rel="$3"

  case "${kind}" in
    file)
      copy_back "${target_root}/${target_rel}" "${source_root}/${source_rel}"
      ;;
    dir)
      local source_dir="${source_root}/${source_rel}"
      local target_dir="${target_root}/${target_rel}"
      local source_file rel_path runtime_file

      if [[ ! -d "${source_dir}" ]]; then
        echo "error: missing source directory ${source_dir}" >&2
        exit 1
      fi

      while IFS= read -r -d '' source_file; do
        rel_path="${source_file#${source_dir}/}"
        runtime_file="${target_dir}/${rel_path}"
        copy_back "${runtime_file}" "${source_file}"
      done < <(find "${source_dir}" -type f -print0 | sort -z)
      ;;
    *)
      echo "error: unsupported sync entry kind '${kind}'" >&2
      exit 1
      ;;
  esac
}

operation="${1:-}"

if [[ "${operation}" == "maps" ]]; then
  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi

  list_maps
  exit 0
fi

map_name="${2:-}"

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

if [[ "${operation}" != "seed" && "${operation}" != "pull" ]]; then
  usage
  exit 1
fi

while IFS='|' read -r kind source_rel target_rel; do
  if [[ -z "${kind}" || "${kind}" == \#* ]]; then
    continue
  fi

  if [[ -z "${source_rel}" || -z "${target_rel}" ]]; then
    echo "error: invalid map entry for '${map_name}': ${kind}|${source_rel}|${target_rel}" >&2
    exit 1
  fi

  if [[ "${operation}" == "seed" ]]; then
    seed_entry "${kind}" "${source_rel}" "${target_rel}"
  else
    pull_entry "${kind}" "${source_rel}" "${target_rel}"
  fi
done < <(list_sync_entries "${map_name}")
