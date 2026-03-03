#!/usr/bin/env bash
set -euo pipefail

host="${1:-}"

if [[ -z "${host}" ]]; then
  echo "usage: scripts/switch.sh <host>" >&2
  exit 1
fi

sudo nixos-rebuild switch --flake ".#${host}"
