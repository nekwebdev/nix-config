#!/usr/bin/env bash
set -euo pipefail

nix build .#nixosConfigurations.bare.config.system.build.toplevel
nix build .#nixosConfigurations.bare.config.system.build.vm
