#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <path/to/file.env>" >&2
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

if [[ "$input_path" == *.sops ]]; then
  echo "error: input already has .sops suffix: $input_path" >&2
  exit 1
fi

output_path="${input_path}.sops"
tmp_out="$(mktemp "${output_path##*/}.XXXXXX")"
cleanup() {
  rm -f "$tmp_out"
}
trap cleanup EXIT

sops --encrypt \
  --filename-override "$output_path" \
  --input-type dotenv \
  --output-type dotenv \
  "$input_path" > "$tmp_out"
chmod 600 "$tmp_out"
mv "$tmp_out" "$output_path"
rm -f "$input_path"

echo "encrypted: $output_path"
