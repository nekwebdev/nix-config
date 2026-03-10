#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
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

environment overrides:
  RUNTIME_CONFIG_USER  Override the user segment used under configs/users/<user>/...
  RUNTIME_CONFIG_HOST  Override the host segment used under configs/users/<user>/hosts/<host>/...
USAGE
}

resolve_runtime_user() {
  if [[ -n "${RUNTIME_CONFIG_USER:-}" ]]; then
    printf '%s\n' "${RUNTIME_CONFIG_USER}"
    return
  fi

  if [[ -n "${USER:-}" ]]; then
    printf '%s\n' "${USER}"
    return
  fi

  id -un
}

resolve_runtime_host() {
  local host_name="${RUNTIME_CONFIG_HOST:-${HOSTNAME:-}}"

  if [[ -z "${host_name}" ]]; then
    host_name="$(hostname 2>/dev/null || true)"
  fi

  host_name="${host_name%%.*}"
  printf '%s\n' "${host_name}"
}

runtime_user="$(resolve_runtime_user)"
runtime_host="$(resolve_runtime_host)"

source_roots=(
  "${repo_root}/configs/common"
  "${repo_root}/configs/users/${runtime_user}/common"
)

if [[ -n "${runtime_host}" ]]; then
  source_roots+=("${repo_root}/configs/users/${runtime_user}/hosts/${runtime_host}")
fi

default_pull_root="${repo_root}/configs/users/${runtime_user}/common"

# Repo-relative pull excludes. Use exact paths or shell-style globs.
pull_exclude_repo_rel_paths=(
  "configs/users/oj/hosts/lotus/niri/colors.kdl"
)

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
# Source paths are relative to layered config roots.
# Target paths are relative to HOME.

dir|dms|.config/DankMaterialShell
ENTRIES
      ;;
    niri)
      cat <<'ENTRIES'
# kind|source_rel|target_rel
# Source paths are relative to layered config roots.
# Target paths are relative to HOME.

dir|niri|.config/niri/dms
ENTRIES
      ;;
    zed)
      cat <<'ENTRIES'
# kind|source_rel|target_rel
# Source paths are relative to layered config roots.
# Target paths are relative to HOME.

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

  mkdir -p "$(dirname "${dst}")"

  if [[ -e "${src}" && -e "${dst}" && "${src}" -ef "${dst}" ]]; then
    echo "skip: source already points at ${dst}"
    return 0
  fi

  cp --dereference "${src}" "${dst}"
  echo "updated ${dst}"
}

is_pull_excluded() {
  local destination_path="$1"
  local destination_rel="${destination_path#${repo_root}/}"
  local pattern

  for pattern in "${pull_exclude_repo_rel_paths[@]}"; do
    if [[ "${destination_rel}" == ${pattern} ]]; then
      echo "skip: pull excluded ${destination_rel}"
      return 0
    fi
  done

  return 1
}

resolve_seed_source_file() {
  local source_rel="$1"
  local selected=""
  local candidate

  for source_root in "${source_roots[@]}"; do
    candidate="${source_root}/${source_rel}"
    if [[ -f "${candidate}" ]]; then
      selected="${candidate}"
    fi
  done

  if [[ -z "${selected}" ]]; then
    echo "error: no source file found for ${source_rel}" >&2
    exit 1
  fi

  printf '%s\n' "${selected}"
}

resolve_pull_destination_file() {
  local source_rel="$1"
  local candidate

  for ((idx=${#source_roots[@]} - 1; idx >= 0; idx--)); do
    candidate="${source_roots[$idx]}/${source_rel}"
    if [[ -e "${candidate}" || -L "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return
    fi
  done

  printf '%s\n' "${default_pull_root}/${source_rel}"
}

seed_dir_sources() {
  local source_rel="$1"
  local source_root source_dir source_file rel_path
  local had_sources=0
  declare -A selected_by_rel=()

  for source_root in "${source_roots[@]}"; do
    source_dir="${source_root}/${source_rel}"
    if [[ ! -d "${source_dir}" ]]; then
      continue
    fi

    had_sources=1
    while IFS= read -r -d '' source_file; do
      rel_path="${source_file#${source_dir}/}"
      selected_by_rel["${rel_path}"]="${source_file}"
    done < <(find "${source_dir}" -type f -print0 | sort -z)
  done

  if [[ "${had_sources}" -eq 0 ]]; then
    echo "error: no source directories found for ${source_rel}" >&2
    exit 1
  fi

  if [[ "${#selected_by_rel[@]}" -eq 0 ]]; then
    echo "error: no source files found for ${source_rel}" >&2
    exit 1
  fi

  while IFS= read -r rel_path; do
    printf '%s|%s\n' "${rel_path}" "${selected_by_rel[${rel_path}]}"
  done < <(printf '%s\n' "${!selected_by_rel[@]}" | LC_ALL=C sort)
}

pull_dir_rel_paths() {
  local source_rel="$1"
  local source_root source_dir source_file rel_path
  local had_sources=0
  declare -A rel_paths=()

  for source_root in "${source_roots[@]}"; do
    source_dir="${source_root}/${source_rel}"
    if [[ ! -d "${source_dir}" ]]; then
      continue
    fi

    had_sources=1
    while IFS= read -r -d '' source_file; do
      rel_path="${source_file#${source_dir}/}"
      rel_paths["${rel_path}"]=1
    done < <(find "${source_dir}" -type f -print0 | sort -z)
  done

  if [[ "${had_sources}" -eq 0 ]]; then
    echo "error: no source directories found for ${source_rel}" >&2
    exit 1
  fi

  if [[ "${#rel_paths[@]}" -eq 0 ]]; then
    echo "error: no source files found for ${source_rel}" >&2
    exit 1
  fi

  printf '%s\n' "${!rel_paths[@]}" | LC_ALL=C sort
}

seed_entry() {
  local kind="$1"
  local source_rel="$2"
  local target_rel="$3"

  case "${kind}" in
    file)
      copy_if_missing "$(resolve_seed_source_file "${source_rel}")" "${target_root}/${target_rel}"
      ;;
    dir)
      local target_dir="${target_root}/${target_rel}"
      local rel_path source_file

      while IFS='|' read -r rel_path source_file; do
        copy_if_missing "${source_file}" "${target_dir}/${rel_path}"
      done < <(seed_dir_sources "${source_rel}")
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
      local destination_file
      destination_file="$(resolve_pull_destination_file "${source_rel}")"

      if is_pull_excluded "${destination_file}"; then
        return 0
      fi

      copy_back "${target_root}/${target_rel}" "${destination_file}"
      ;;
    dir)
      local target_dir="${target_root}/${target_rel}"
      local rel_path runtime_file source_file

      while IFS= read -r rel_path; do
        runtime_file="${target_dir}/${rel_path}"
        source_file="$(resolve_pull_destination_file "${source_rel}/${rel_path}")"

        if is_pull_excluded "${source_file}"; then
          continue
        fi

        copy_back "${runtime_file}" "${source_file}"
      done < <(pull_dir_rel_paths "${source_rel}")
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
