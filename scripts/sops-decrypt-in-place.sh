#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <path/to/file.env.sops>" >&2
  exit 2
fi

arg="$1"
if [[ "$arg" == file=* ]]; then
  input_path="${arg#file=}"
else
  input_path="$arg"
fi

if [ ! -f "$input_path" ]; then
  echo "error: file not found: $input_path" >&2
  exit 1
fi

if [[ "$input_path" != *.sops ]]; then
  echo "error: expected a .sops file: $input_path" >&2
  exit 1
fi

output_path="${input_path%.sops}"
if [ "$output_path" = "$input_path" ]; then
  echo "error: could not derive decrypted output path from: $input_path" >&2
  exit 1
fi

if [ -f /home/oj/.ssh/nixos-sops ]; then
  if [ -z "${SOPS_AGE_KEY:-}" ] && [ -z "${SOPS_AGE_KEY_FILE:-}" ] && [ -z "${SOPS_AGE_KEY_CMD:-}" ]; then
    if command -v ssh-to-age >/dev/null 2>&1; then
      export SOPS_AGE_KEY_CMD='ssh-to-age -private-key -i /home/oj/.ssh/nixos-sops'
    else
      export SOPS_AGE_KEY_CMD='nix run nixpkgs#ssh-to-age -- -private-key -i /home/oj/.ssh/nixos-sops'
    fi
  fi

  if [ -z "${SOPS_AGE_SSH_PRIVATE_KEY_FILE:-}" ]; then
    export SOPS_AGE_SSH_PRIVATE_KEY_FILE=/home/oj/.ssh/nixos-sops
  fi
fi

tmp_out="$(mktemp "${output_path##*/}.XXXXXX")"
cleanup() {
  rm -f "$tmp_out"
}
trap cleanup EXIT

sops --decrypt --input-type dotenv --output-type dotenv "$input_path" > "$tmp_out"
chmod 600 "$tmp_out"
mv "$tmp_out" "$output_path"
rm -f "$input_path"

echo "decrypted: $output_path"
