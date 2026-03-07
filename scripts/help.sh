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
  just new-user user=<user> [sops_key_path=<path>]
  just new-host host=<host> user=<user> [sops_key_path=<path>]

Secrets and keys:
  just sops-vpn-credentials [recipients_file=<path>]
  just vaultwarden-keys <user> <host> <age_item> <ssh_item> [target_root=/mnt] [server=<url>]

Runtime config:
  just config-update
  just update

Raw recipe list:
  just --list --unsorted
EOF
