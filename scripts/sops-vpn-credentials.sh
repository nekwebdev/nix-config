#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: just sops-vpn-credentials [recipients_file=<path>]
EOF
}

profile="nordvpn"
recipients_file="${1:-}"
secret_file="secrets/vpn.yaml"

if [[ $# -gt 1 ]]; then
  echo "error: too many arguments" >&2
  usage
  exit 1
fi

if [[ -z "${recipients_file}" ]]; then
  recipients_file="secrets/recipients/users/oj.txt"
fi

trim() {
  local line="$1"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s\n' "${line}"
}

yaml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s\n' "${value}"
}

declare -a recipients=()

add_recipient() {
  local candidate
  candidate="$(trim "$1")"
  if [[ -z "${candidate}" ]]; then
    return
  fi

  for existing in "${recipients[@]}"; do
    if [[ "${existing}" == "${candidate}" ]]; then
      return
    fi
  done

  recipients+=("${candidate}")
}

if ! command -v sops >/dev/null 2>&1; then
  echo "error: sops is required" >&2
  exit 1
fi

if [[ -n "${SOPS_AGE_RECIPIENTS:-}" ]]; then
  while IFS= read -r recipient; do
    add_recipient "${recipient}"
  done < <(printf '%s' "${SOPS_AGE_RECIPIENTS}" | tr ',' '\n')
elif [[ -n "${SOPS_AGE_RECIPIENT:-}" ]]; then
  add_recipient "${SOPS_AGE_RECIPIENT}"
elif [[ -f "${recipients_file}" ]]; then
  while IFS= read -r line; do
    line="${line%%#*}"
    add_recipient "${line}"
  done <"${recipients_file}"
fi

if [[ ${#recipients[@]} -eq 0 ]]; then
  cat >&2 <<EOF
error: no SOPS recipients found
hint: set SOPS_AGE_RECIPIENTS, or run: just sops-vpn-credentials recipients_file=<path>
EOF
  exit 1
fi

read -r -p "NordVPN username: " vpn_username
read -r -s -p "NordVPN password: " vpn_password
echo
read -r -s -p "Confirm NordVPN password: " vpn_password_confirm
echo

if [[ "${vpn_password}" != "${vpn_password_confirm}" ]]; then
  echo "error: passwords do not match" >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

escaped_username="$(yaml_escape "${vpn_username}")"
escaped_password="$(yaml_escape "${vpn_password}")"

cat >"${tmp}" <<EOF
vpn:
  "nordvpn-username": "${escaped_username}"
  "nordvpn-password": "${escaped_password}"
EOF

mkdir -p "$(dirname "${secret_file}")"
sops_recipients_csv="$(IFS=,; echo "${recipients[*]}")"
sops --encrypt --age "${sops_recipients_csv}" --input-type yaml --output-type yaml "${tmp}" >"${secret_file}"

echo "wrote ${secret_file}"
echo "secret keys:"
echo "  - vpn/nordvpn-username"
echo "  - vpn/nordvpn-password"
echo "recipient count: ${#recipients[@]}"
echo "if ${secret_file} is new, add it to git so flake evaluation can see it"
