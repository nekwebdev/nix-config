#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: just vaultwarden-keys user=<user> host=<host> age_item=<item> ssh_item=<item> [target_root=<path>] [server=<url>]

The script expects key material in Vaultwarden item notes:
- age_item notes: full age key file content (for keys.txt)
- ssh_item notes: SSH private key content (PEM/OpenSSH)
USAGE
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: required command not found: ${cmd}" >&2
    exit 1
  fi
}

resolve_item_id() {
  local item_name="$1"
  local ids

  ids="$(bw list items --search "${item_name}" | jq -r --arg item_name "${item_name}" '.[] | select(.name == $item_name) | .id')"

  mapfile -t id_array < <(printf '%s\n' "${ids}" | sed '/^$/d')

  if [[ "${#id_array[@]}" -eq 0 ]]; then
    echo "error: no Vaultwarden item found with exact name: ${item_name}" >&2
    exit 1
  fi

  if [[ "${#id_array[@]}" -gt 1 ]]; then
    echo "error: multiple Vaultwarden items match exact name '${item_name}'; use unique names" >&2
    printf 'matching ids:\n' >&2
    printf '  - %s\n' "${id_array[@]}" >&2
    exit 1
  fi

  printf '%s\n' "${id_array[0]}"
}

read_item_notes() {
  local item_id="$1"
  local item_name="$2"
  local notes

  notes="$(bw get item "${item_id}" | jq -r '.notes // empty')"

  if [[ -z "${notes}" ]]; then
    echo "error: Vaultwarden item '${item_name}' has empty notes" >&2
    exit 1
  fi

  printf '%s\n' "${notes}"
}

user="${1:-}"
host="${2:-}"
age_item="${3:-}"
ssh_item="${4:-}"
target_root="${5:-/mnt}"
server_url="${6:-}"

if [[ -z "${user}" || -z "${host}" || -z "${age_item}" || -z "${ssh_item}" ]]; then
  usage
  exit 1
fi

if [[ $# -gt 6 ]]; then
  echo "error: too many arguments" >&2
  usage
  exit 1
fi

if [[ ! "${user}" =~ ^[a-z][a-z0-9]*$ ]]; then
  echo "error: user must match ^[a-z][a-z0-9]*$" >&2
  exit 1
fi

if [[ ! "${host}" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "error: host must match ^[a-z][a-z0-9-]*$" >&2
  exit 1
fi

require_command bw
require_command jq
require_command ssh-keygen
require_command install

if [[ -n "${server_url}" ]]; then
  bw config server "${server_url}" >/dev/null
fi

if ! bw status >/dev/null 2>&1; then
  cat >&2 <<'EOF_STATUS'
error: unable to query bw status
hint: ensure Bitwarden CLI is installed and configured
EOF_STATUS
  exit 1
fi

bw_status="$(bw status | jq -r '.status // "unknown"')"
if [[ "${bw_status}" != "unlocked" ]]; then
  cat >&2 <<'EOF_UNLOCK'
error: Vaultwarden session is not unlocked
hint:
  bw login --apikey        # or: bw login
  export BW_SESSION="$(bw unlock --raw)"
EOF_UNLOCK
  exit 1
fi

bw sync >/dev/null

age_item_id="$(resolve_item_id "${age_item}")"
ssh_item_id="$(resolve_item_id "${ssh_item}")"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

age_tmp="${tmp_dir}/age-keys.txt"
ssh_priv_tmp="${tmp_dir}/ssh-private"
ssh_pub_tmp="${tmp_dir}/ssh-private.pub"

read_item_notes "${age_item_id}" "${age_item}" >"${age_tmp}"
read_item_notes "${ssh_item_id}" "${ssh_item}" >"${ssh_priv_tmp}"

# Normalize potential CRLF content from note fields.
sed -i 's/\r$//' "${age_tmp}" "${ssh_priv_tmp}"

if ! grep -q 'AGE-SECRET-KEY-' "${age_tmp}"; then
  echo "warning: age key file does not contain AGE-SECRET-KEY marker" >&2
fi

if ! grep -q '^-----BEGIN .*PRIVATE KEY-----$' "${ssh_priv_tmp}"; then
  echo "error: ssh item notes do not look like a private key" >&2
  exit 1
fi

target_root="${target_root%/}"
if [[ -z "${target_root}" ]]; then
  target_root="/"
fi

target_home="${target_root}/home/${user}"
age_key_file="${target_home}/.config/sops/age/keys.txt"
ssh_private_key="${target_home}/.ssh/nixos-${host}"
ssh_public_key="${ssh_private_key}.pub"

install -d -m 0700 "${target_home}/.ssh"
install -d -m 0700 "$(dirname "${age_key_file}")"

install -m 0600 "${age_tmp}" "${age_key_file}"
install -m 0600 "${ssh_priv_tmp}" "${ssh_private_key}"

ssh-keygen -y -f "${ssh_private_key}" >"${ssh_pub_tmp}"
install -m 0644 "${ssh_pub_tmp}" "${ssh_public_key}"

ownership_applied=0
target_passwd="${target_root}/etc/passwd"
if [[ -f "${target_passwd}" ]]; then
  uid_gid="$(awk -F: -v u="${user}" '$1 == u {print $3":"$4; exit}' "${target_passwd}")"
  if [[ -n "${uid_gid}" ]]; then
    chown -R "${uid_gid}" "${target_home}/.ssh" "${target_home}/.config/sops/age"
    ownership_applied=1
  fi
fi

echo "wrote age key file: ${age_key_file}"
echo "wrote ssh key pair: ${ssh_private_key} (+ .pub)"

if [[ "${ownership_applied}" -eq 1 ]]; then
  echo "applied target ownership from ${target_passwd}"
else
  echo "warning: target ownership not applied yet (user '${user}' missing from ${target_passwd})"
  echo "rerun this script after nixos-install to apply ownership, or chown from target root later"
fi

echo
if [[ "${target_root}" != "/" ]]; then
  echo "initial install hint:"
  echo "  SOPS_AGE_KEY_FILE='${age_key_file}' nixos-install --flake .#${host}"
else
  echo "initial install hint:"
  echo "  SOPS_AGE_KEY_FILE='${age_key_file}' nixos-rebuild switch --flake .#${host}"
fi
