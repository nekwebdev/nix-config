#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: just new-user user=<user> [sops_key_path=<path>]

Environment overrides:
  SOPS_KEY_PATH    Existing SSH key path (private key path or public key path).
EOF
}

expand_path() {
  local raw="$1"
  if [[ "${raw}" == ~/* ]]; then
    printf '%s\n' "${HOME}/${raw#~/}"
    return
  fi

  printf '%s\n' "${raw}"
}

extract_ssh_recipient() {
  local key_path="$1"
  awk 'NF >= 2 {print $1 " " $2; exit}' "${key_path}"
}

replace_user_placeholders() {
  local file_path="$1"
  local user_name="$2"
  local user_module="$3"

  sed -i \
    -e "s/\\<oj\\>/${user_name}/g" \
    -e "s/Oj/${user_module}/g" \
    "${file_path}"
}

user="${1:-}"
shift || true
sops_key_input="${1:-${SOPS_KEY_PATH:-}}"
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
hm_user_file="modules/homeModules/users/${user}.nix"
hm_user_dir="modules/homeModules/users/${user}"
user_configs_dir="configs/users/${user}"
source_nixos_user_file="modules/nixosModules/users/oj.nix"
source_hm_user_file="modules/homeModules/users/oj.nix"
source_hm_user_dir="modules/homeModules/users/oj"
source_user_configs_dir="configs/users/oj"
recipient_file="secrets/recipients/users/${user}.txt"

if [[ -e "${nixos_user_file}" || -e "${hm_user_file}" || -e "${hm_user_dir}" || -e "${user_configs_dir}" ]]; then
  echo "error: user '${user}' already exists (one or more target files already present)" >&2
  exit 1
fi

if [[ ! -f "${source_nixos_user_file}" || ! -f "${source_hm_user_file}" || ! -d "${source_hm_user_dir}" || ! -d "${source_user_configs_dir}" ]]; then
  echo "error: expected oj source modules are missing" >&2
  echo "required sources:" >&2
  echo "  - ${source_nixos_user_file}" >&2
  echo "  - ${source_hm_user_file}" >&2
  echo "  - ${source_hm_user_dir}/" >&2
  echo "  - ${source_user_configs_dir}/" >&2
  exit 1
fi

if [[ -z "${sops_key_input}" ]]; then
  if ! command -v ssh-keygen >/dev/null 2>&1; then
    echo "error: ssh-keygen is required to generate a new key" >&2
    exit 1
  fi

  private_key_path="${HOME}/.ssh/nixos-${user}-sops"
  public_key_path="${private_key_path}.pub"

  if [[ -f "${private_key_path}" || -f "${public_key_path}" ]]; then
    if [[ ! -f "${private_key_path}" || ! -f "${public_key_path}" ]]; then
      echo "error: partial key material found at ${private_key_path}[.pub]" >&2
      exit 1
    fi
    echo "reusing existing SSH key pair:"
    echo "  private: ${private_key_path}"
    echo "  public:  ${public_key_path}"
  else
    mkdir -p "$(dirname "${private_key_path}")"
    host_name="${HOSTNAME:-$(hostname 2>/dev/null || echo unknown-host)}"
    ssh_key_comment="sops-${user}@${host_name}"

    echo "creating SSH key: ssh-keygen will prompt for a key passphrase"
    ssh-keygen -t ed25519 -C "${ssh_key_comment}" -f "${private_key_path}"
    chmod 600 "${private_key_path}"
    chmod 644 "${public_key_path}"

    echo "generated SSH key pair:"
    echo "  private: ${private_key_path}"
    echo "  public:  ${public_key_path}"
  fi
else
  candidate_path="$(expand_path "${sops_key_input}")"

  if [[ "${candidate_path}" == *.pub ]]; then
    public_key_path="${candidate_path}"
    private_key_path="${candidate_path%.pub}"
  elif [[ -f "${candidate_path}.pub" ]]; then
    private_key_path="${candidate_path}"
    public_key_path="${candidate_path}.pub"
  elif [[ -f "${candidate_path}" ]]; then
    public_key_path="${candidate_path}"
    private_key_path="${candidate_path%.pub}"
  else
    echo "error: key path not found: ${candidate_path}" >&2
    exit 1
  fi
fi

if [[ ! -f "${public_key_path}" ]]; then
  echo "error: SSH public key not found: ${public_key_path}" >&2
  exit 1
fi

sops_recipient="$(extract_ssh_recipient "${public_key_path}")"
if [[ -z "${sops_recipient}" ]]; then
  echo "error: unable to read SSH recipient from: ${public_key_path}" >&2
  exit 1
fi

key_name="$(basename "${private_key_path}")"
if [[ -z "${key_name}" || "${key_name}" == "." || "${key_name}" == "/" ]]; then
  echo "error: invalid key name derived from path: ${private_key_path}" >&2
  exit 1
fi

target_key_path="/home/${user}/.ssh/${key_name}"

mkdir -p "$(dirname "${nixos_user_file}")" "$(dirname "${hm_user_file}")"

cp "${source_nixos_user_file}" "${nixos_user_file}"
cp "${source_hm_user_file}" "${hm_user_file}"
cp -R "${source_hm_user_dir}" "${hm_user_dir}"
cp -R "${source_user_configs_dir}" "${user_configs_dir}"

replace_user_placeholders "${nixos_user_file}" "${user}" "${user_module_name}"
replace_user_placeholders "${hm_user_file}" "${user}" "${user_module_name}"

while IFS= read -r -d '' hm_fragment; do
  replace_user_placeholders "${hm_fragment}" "${user}" "${user_module_name}"
done < <(find "${hm_user_dir}" -type f -name '*.nix' -print0)

sed -i -E \
  "s|sopsUserKeyPath = \".*\";|sopsUserKeyPath = \"${target_key_path}\";|" \
  "${nixos_user_file}"

echo "created ${nixos_user_file}"
echo "created ${hm_user_file}"
echo "created ${hm_user_dir}/"
echo "created ${user_configs_dir}/"

mkdir -p "$(dirname "${recipient_file}")"
cat >"${recipient_file}" <<EOF_RECIPIENT
# SOPS recipient for user ${user}
# Local source key: ${public_key_path}
# Expected target private key path: ${target_key_path}
${sops_recipient}
EOF_RECIPIENT

echo "created ${recipient_file}"
echo "important: copy private key to target host at ${target_key_path} before rebuild/switch"

echo "bootstrapping password secret for ${user}"
bash "${script_dir}/sops-user-password.sh" "${user}" "${recipient_file}"

echo "if secrets/users.yaml was created or updated, add it to git"
