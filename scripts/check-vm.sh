#!/usr/bin/env bash
set -euo pipefail

nix build .#nixosConfigurations.lotus.config.system.build.toplevel
nix build .#nixosConfigurations.lotus.config.system.build.vm
