#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: just sops-user-password user=<user> [recipients_file=<path>]
EOF
}

user="${1:-}"
recipients_file="${2:-}"
secret_file="secrets/users.yaml"

if [[ -z "${user}" ]]; then
  usage
  exit 1
fi

if [[ $# -gt 2 ]]; then
  echo "error: too many arguments" >&2
  usage
  exit 1
fi

if [[ -z "${recipients_file}" ]]; then
  recipients_file="secrets/recipients/users/${user}.txt"
fi

trim() {
  local line="$1"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s\n' "${line}"
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
else
  if [[ -f "${recipients_file}" ]]; then
    while IFS= read -r line; do
      line="${line%%#*}"
      add_recipient "${line}"
    done <"${recipients_file}"
  fi
fi

if [[ ${#recipients[@]} -eq 0 ]]; then
  cat >&2 <<EOF
error: no SOPS recipients found
hint: set SOPS_AGE_RECIPIENTS, or run: just sops-user-password user=${user} recipients_file=<path>
EOF
  exit 1
fi

if command -v mkpasswd >/dev/null 2>&1; then
  hash_cmd=(mkpasswd -m yescrypt)
elif command -v openssl >/dev/null 2>&1; then
  hash_cmd=(openssl passwd -6)
else
  echo "error: mkpasswd or openssl is required to create a password hash" >&2
  exit 1
fi

read -r -s -p "Password for ${user}: " password
echo
read -r -s -p "Confirm password: " password_confirm
echo

if [[ "${password}" != "${password_confirm}" ]]; then
  echo "error: passwords do not match" >&2
  exit 1
fi

password_hash="$("${hash_cmd[@]}" "${password}")"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

cat >"${tmp}" <<EOF
users:
  ${user}-password: "${password_hash}"
EOF

mkdir -p "$(dirname "${secret_file}")"
sops_recipients_csv="$(IFS=,; echo "${recipients[*]}")"
sops --encrypt --age "${sops_recipients_csv}" --input-type yaml --output-type yaml "${tmp}" >"${secret_file}"

echo "wrote ${secret_file}"
echo "secret key path: users/${user}-password"
echo "recipient count: ${#recipients[@]}"
echo "if secrets/users.yaml is new, add it to git so flake evaluation can see it"
