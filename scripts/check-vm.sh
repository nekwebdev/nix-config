#!/usr/bin/env bash
set -euo pipefail

nix build "path:$PWD#nixosConfigurations.lotus.config.system.build.toplevel"
nix build "path:$PWD#nixosConfigurations.lotus.config.system.build.vm"
