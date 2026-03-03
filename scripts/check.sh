#!/usr/bin/env bash
set -euo pipefail

nix flake check --show-trace -L
