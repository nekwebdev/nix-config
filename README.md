# nixos Configuration

Minimal dendritic NixOS + Home Manager setup:

- `flake.nix` stays thin: `mkFlake + import-tree ./modules`.
- everything under `modules/` is a flake-parts module.
- host modules explicitly import the NixOS modules they want.
- user modules explicitly import the Home Manager modules they want.
- Home Manager is integrated through NixOS only.
- user identity lives in the matching NixOS user module and is passed into HM through `osConfig`.
- wrapped programs use `wrappers` only.

## Hosts

| Host | Role | Storage | User profile | Assistant modules |
| --- | --- | --- | --- | --- |
| `lotus` | desktop baseline | existing host layout | `ojLotusProfile` | Codex, Claude, Pi, Hermes, websearch proxy |
| `aura` | Lenovo ThinkPad X9-15 Aura | Disko full-disk LUKS+Btrfs with tmpfs root and `preservation` | `ojAuraProfile` | Codex only |

Aura uses `modules/nixosModules/hosts/aura/disko.nix` for the destructive install-time disk layout and `modules/nixosModules/hosts/aura/preservation.nix` for persisted state. Its default Disko target is `/dev/nvme0n1`.

## Layout

- `modules/flake-parts.nix`: shared flake-parts settings (`systems`, treefmt).
- `modules/dev/*.nix`: optional flake dev shells per language or environment.
- `modules/nixosModules/*`: exported NixOS modules and hosts.
- `modules/nixosModules/users/<user>.nix`: typed user contract plus system user declaration.
- `modules/homeModules/programs/*`: reusable Home Manager feature modules.
- `modules/homeModules/users/<user>/*`: user base and profile modules.
- `modules/homeModules/users/<user>/base.nix`: shared per-user HM baseline.
- `modules/homeModules/users/<user>/profile.nix` or `*-profile.nix`: editable user-specific HM packages and session config.
- `configs/common/*`: global fallback runtime config defaults.
- `configs/users/<user>/common/*`: per-user runtime config defaults.
- `configs/users/<user>/hosts/<host>/*`: per-user host-specific runtime config overrides.
- `modules/wrappedPrograms/*`: per-system wrapped packages.

## Commands

```bash
just help
just fmt
just check
just check-vm host=<host>
just switch host=<host>
just update
just new-user user=<user>
just new-host host=<host> user=<user>
just config-update
```

## Temporary NVIDIA CDI Override

- `modules/nixosModules/programs/nvidia.nix` contains a local `services.udev.extraRules` workaround for an upstream nixpkgs typo in `nvidia-container-toolkit` (`nvidia-container-toolkit-cdi-generator.service'`).
- On every input update (`just update` / `flake.lock` changes), check whether upstream fixed `nixos/modules/services/hardware/nvidia-container-toolkit/default.nix`.
- Remove the local override as soon as upstream is fixed.

## Development Shells

`just` remains the public runner for repo tasks. Dev shells are optional, self-contained language environments.

Current shell:

```bash
nix develop
# or
nix develop .#rust
```

The Rust shell is intended for Rust package or tooling work and includes:

- Rust toolchain binaries from `nixpkgs`
- common native build inputs (`pkg-config`, `openssl`, `cmake`, `python3`)
- helper commands on `PATH`: `check`, `test`, `fmt`, `lint`, `run`, `watch`, `doc`, `rust-info`

## Per-project direnv + flake

For a project folder that has its own `flake.nix`, the simplest setup is:

1. Make sure `.direnv/` is ignored by Git.

This repo already ignores `.direnv/` globally in `.gitignore`, which is the right pattern for the per-project direnv cache.

2. Trust and activate the environment once:

```bash
direnv allow
```

After that, direnv automatically loads the flake environment whenever you `cd` into the folder.

Why this is a good thing:

- the environment is declared next to the project, so it is reproducible
- activation is automatic, so you do not need to remember `nix develop` every time
- `direnv allow` is an explicit trust step, so the shell only loads after you review the `.envrc`
- the per-directory cache stays local in `.direnv/` instead of polluting the repo

You may also want to check that your shell has direnv integration enabled and that the flake actually defines a dev shell for the project you are entering.

## Backlog note

- Add `borgmatic` for backups.

## Deployment Guides

- fresh install from a live ISO: [docs/install-new-system.md](docs/install-new-system.md)
- changes on an existing host: [docs/deploy-existing-system.md](docs/deploy-existing-system.md)
- config mutability and switch behavior: [docs/config-lifecycle.md](docs/config-lifecycle.md)

`just check-vm host=<host>` is the preferred final validation on a 3rd party machine because it builds `toplevel` and VM artifacts without switching the running host.
`just config-update` updates the active layered runtime config sources in `configs/users/<user>/{common,hosts/<host>}` from the current system state.

## Assistant Modules

Assistant tooling is split by module:

- `homeModules.codex`: Codex CLI, Codex config sync, `mcp-nixos`, and Codex managed memory/rules.
- `homeModules.claude`: Claude Code and Claude MCP/settings sync.
- `homeModules.pi`: Pi-related user ignores/aliases.
- `nixosModules.hermes`: root-owned Hermes service and SOPS-backed Hermes env files.
- `nixosModules.pi`: system Pi bootstrap plus `mise`, `ffmpeg`, and `yt-dlp`.

Hosts opt into these explicitly. Aura imports only `homeModules.codex`; Lotus imports the full stack.

## Aura Install Notes

Aura is intentionally different from the generic scaffold:

- Disko wipes and recreates the full disk selected as `disk.main`.
- The runtime root filesystem is tmpfs.
- Persistent system/user state is declared under `/persistent` with `preservation`.
- `~/.ssh` is preserved for `oj`, so place the installed machine's signing key at `/home/oj/.ssh/nixos-aura` after first boot.
- Aura does not use SOPS, Hermes, Claude, or Pi unless those modules are added later.

## VPN OVPN workflow

1. Put OpenVPN profile files in `~/.config/ovpn/`:

```bash
mkdir -p ~/.config/ovpn
cp /path/to/provider/*.ovpn ~/.config/ovpn/
```

2. Rebuild once (or manually start the import service):

```bash
just check
```

`vpn-profile-import` imports `.ovpn` files from `~/.config/ovpn` into NetworkManager.

- Existing imported VPN connection names are kept; only missing profiles are imported.
- Username/password are not stored by this repo; enter credentials the first time you connect in NetworkManager.

If you add new `.ovpn` files later and want to import immediately without rebuilding:

```bash
sudo systemctl start vpn-profile-import.service
```

If you edit an existing `.ovpn` and want NetworkManager to use the updated version, delete that VPN connection in NetworkManager first, then run the import service again.

## Password bootstrap behavior

- User modules use a temporary bootstrap password hash (`changeme`) for first account creation.
- A fish reminder is shown until `passwd` succeeds once in fish.

## Hermes Telegram secrets via sops-nix

- Telegram runtime env for `hermes-agent` is sourced from one SOPS-encrypted dotenv file at `secrets/hermes-telegram.env.sops`.
- The decrypted runtime file is provided to the service via `services.hermes-agent.environmentFiles`.
- Required keys in the encrypted dotenv payload:
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_ALLOWED_USERS`
- Machine decrypt identity location: `/home/oj/.ssh/nixos-sops`.
- Private key backup workflow is manual: store backup in Bitwarden yourself.
- No Bitwarden CLI (`bw`) is used or required by this repo for Telegram secret management.

## Hermes OpenAI secrets via sops-nix

- Direct OpenAI API env for `hermes-agent` is sourced from one SOPS-encrypted dotenv file at `secrets/hermes-openai.env.sops`.
- The decrypted runtime file is provided to the service via `services.hermes-agent.environmentFiles`.
- Required keys in the encrypted dotenv payload:
  - `OPENAI_API_KEY`
- Optional keys:
  - `OPENAI_BASE_URL` (only if you want to override the default OpenAI endpoint)
- This OpenAI key is used for direct auxiliary tasks like compression; it does not affect `openai-codex` OAuth model calls.

## Canon USB printer (LBP6000/LBP6018)

Working setup for this host (CUPS queue + default printer):

```bash
lpadmin -p Canon_LBP6018 -E \
  -v 'usb://Canon/LBP6000/LBP6018?serial=0000A1B27M28' \
  -m 'canon/CanonLBP-3010-3018-3050.ppd'
lpoptions -d Canon_LBP6018
```

Verify:

```bash
lpstat -t
```

Queue a quick test page:

```bash
echo "Canon printer test from CUPS" | lp -d Canon_LBP6018
```

If USB URI changes, list devices and update `-v`:

```bash
lpinfo -v
```

## Using Parts of This Repo (WIP)

### 1) Runtime config files (`configs/*`)

Use this when app configs are UI-mutated and should be copy-synced instead of immutable HM links.

- Layer order (lowest -> highest):
  - `configs/common/*`
  - `configs/users/<user>/common/*`
  - `configs/users/<user>/hosts/<host>/*`
- On activation, HM runs `scripts/runtime-config-helper.sh seed <map>` to copy missing runtime files into `~/.config/*`.
- To sync runtime changes back into the repo, run:

```bash
just config-update
just config-update dry=--dry-run
```

- Pull-back exclusions (for intentionally volatile files) are defined in:
  - `scripts/runtime-config-helper.sh` (`pull_exclude_repo_rel_paths`)

### 2) User and host scaffolding

`just new-user` and `just new-host` render static templates from `scripts/templates/` that mirror the current `oj` + `lotus` baseline, instead of cloning live modules from the repo tree.

After `just new-user user=<user>`:

- edit `modules/nixosModules/users/<user>.nix` for `githubUsername`, email, admin state, and any derived groups
- edit `modules/homeModules/users/<user>/profile.nix` or `*-profile.nix` for packages, flatpaks, and session variables

### 3) Wrapped programs and wrappers
Current wrapped package outputs are `monsters-and-memories-launcher` and `orca-slicer`. Pinokio was removed.
