#!/usr/bin/env bash
set -euo pipefail

host="${1:-}"

if [[ -z "${host}" ]]; then
  host="${HOSTNAME:-$(hostname --short 2>/dev/null || hostname 2>/dev/null || true)}"
fi

if [[ -z "${host}" ]]; then
  echo "error: could not determine hostname; pass one explicitly (just switch host=<host>)" >&2
  exit 1
fi

sudo nixos-rebuild switch --flake ".#${host}"
