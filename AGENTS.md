# AGENTS.md

## Mandatory workflow
- Use one or more specialist agents as needed, but **only read the agent dossier(s) you actually use**.
- Attribute work by agent name (who did what).

## Repo constraints (PRD)
- platform: **x86_64-linux only**
- platform enforcement: flake outputs/checks must target `x86_64-linux` only
- composition: **flake-parts** is core to the design pattern
- module loading: **import-tree** recursively loads the `modules/` tree
- architecture: keep a lean baseline (`lotus` host + baseline user module) and extend with scaffolding boilerplate
- composition model: host module explicitly imports NixOS modules; user module explicitly imports HM modules
- HM integration: through NixOS only (no standalone HM output path)
- rule: **HM-first** (if it can be Home Manager, it must be Home Manager)
- HM-first exceptions (allowed in NixOS modules): boot/kernel/hardware, filesystems, networking/firewall, users/groups, PAM/sudo/polkit, root-owned services
- users policy: host-declared users are normal users and must include `wheel`
- VPN convention: put user-supplied `.ovpn` files in `~/.config/ovpn/`; `policy.nix` imports them at runtime via `vpn-profile-import`
- wrapped programs: use **wrappers** only (do not use `wrapper-modules`)
- formatting: **treefmt-nix** (Nix formatter: **alejandra**)
- runner: **justfile** calling `/scripts/*.sh`

## Commands
```bash
just help
just fmt
just check
just check-vm
just switch host=<host>
just new-user user=<user>
just new-host host=<host> user=<user>
```

## Hard rules
- keep `flake.nix` thin (inputs + `mkFlake` + `import-tree ./modules`)
- keep module exports in `modules/*` (`flake.nixosModules.*`, `flake.homeModules.*`, `perSystem.packages.*`)
- add new hosts/users via scaffolding scripts first, then edit generated modules
- do not reintroduce toggle-file/module-ID/unique-group policy frameworks unless PRD is explicitly updated
- do not reintroduce standalone HM outputs unless PRD is explicitly updated
- do not use `wrapper-modules` in this repo unless PRD is explicitly updated
- keep logic out of `justfile`; scripts live in `/scripts`
- do not run `just switch` on this already-configured machine during validation; use `just check` + `just check-vm`
- commit and review `flake.lock` input updates intentionally; do not drift input versions accidentally
- keep the temporary NVIDIA CDI udev override in `modules/nixosModules/programs/nvidia.nix` until nixpkgs fixes the upstream trailing-quote bug in `nixos/modules/services/hardware/nvidia-container-toolkit/default.nix`; re-check on every input/`flake.lock` update and remove the override once upstream is fixed
- when drafting commit messages, use a Conventional Commit subject; if there is a body, format it with `-` bullets
- do not commit secrets (tokens, private keys, machine-specific credentials) to tracked files

## Merge gates (required)
- run `just fmt` before merge
- run `just check` before merge
- run `just check-vm` before merge

## Test expectations
- any new/changed module must keep evaluation passing under `just check`
- host or user scaffolding changes must include `just check-vm` verification notes

## Reminders
- Never run git commands that would write to the repo directly without asking. If a signed `git commit` is needed, ask to run it outside the sandbox.
- Always use the fish style for bash commands.
- For validation when unstaged changes are expected, prefer path-based flake refs so checks see the working tree instead of Git index snapshots (for example `nix flake check --show-trace -L "path:$PWD"` and `nix build "path:$PWD#nixosConfigurations.<host>.config.system.build.vm"`).
- No commit is needed; `git add -A` (or `git add <paths>`) is enough.
