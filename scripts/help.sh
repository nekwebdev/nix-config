#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
NixOS repo task runner

Core:
  just fmt
  just check
  just check-vm
  just switch host=<host>

Scaffolding:
  just new-user user=<user>
  just new-host host=<host> user=<user>

Runtime config:
  just config-update
  just update

Raw recipe list:
  just --list --unsorted
EOF
