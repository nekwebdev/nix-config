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

Secrets (dotenv in-place helpers):
  just sops-decrypt-env [file=.env.sops]
  just sops-encrypt-env [file=.env]

Raw recipe list:
  just --list --unsorted
EOF
