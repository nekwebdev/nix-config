# nixos Configuration

Minimal dendritic NixOS + Home Manager setup:

- `flake.nix` stays thin: `mkFlake + import-tree ./modules`.
- everything under `modules/` is a flake-parts module.
- host modules explicitly import the NixOS modules they want.
- user modules explicitly import the Home Manager modules they want.
- Home Manager is integrated through NixOS only.
- user identity lives in the matching NixOS user module and is passed into HM through `osConfig`.
- wrapped programs use `wrappers` only.

## Layout

- `modules/flake-parts.nix`: shared flake-parts settings (`systems`, treefmt).
- `modules/dev/*.nix`: optional flake dev shells per language or environment.
- `modules/nixosModules/*`: exported NixOS modules and hosts.
- `modules/nixosModules/users/<user>.nix`: typed user contract plus system user declaration.
- `modules/homeModules/*`: exported Home Manager user profiles.
- `modules/homeModules/users/<user>/base.nix`: shared per-user HM baseline.
- `modules/homeModules/users/<user>/profile.nix`: editable user-specific HM packages and session config.
- `configs/common/*`: global fallback runtime config defaults.
- `configs/users/<user>/common/*`: per-user runtime config defaults.
- `configs/users/<user>/hosts/<host>/*`: per-user host-specific runtime config overrides.
- `modules/wrappedPrograms/*`: per-system wrapped packages.

## Commands

```bash
just help
just fmt
just check
just check-vm
just switch host=<host>
just update
just new-user user=<user>
just new-host host=<host> user=<user>
just config-update
```

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

## Backlog note

- Add `borgmatic` for backups.

## Deployment Guides

- fresh install from a live ISO: [docs/install-new-system.md](/home/oj/.config/nixos/docs/install-new-system.md)
- changes on an existing host: [docs/deploy-existing-system.md](/home/oj/.config/nixos/docs/deploy-existing-system.md)
- config mutability and switch behavior: [docs/config-lifecycle.md](/home/oj/.config/nixos/docs/config-lifecycle.md)

`just check-vm` is the preferred final validation on a 3rd party machine because it builds `toplevel` and VM artifacts without switching the running host.
`just config-update` updates the active layered runtime config sources in `configs/users/<user>/{common,hosts/<host>}` from the current system state.

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
```

- Pull-back exclusions (for intentionally volatile files) are defined in:
  - `scripts/runtime-config-helper.sh` (`pull_exclude_repo_rel_paths`)

### 2) User and host scaffolding

`just new-user` and `just new-host` render static templates from `scripts/templates/` that mirror the current `oj` + `lotus` baseline, instead of cloning live modules from the repo tree.

After `just new-user user=<user>`:

- edit `modules/nixosModules/users/<user>.nix` for `githubUsername`, email, admin state, and any derived groups
- edit `modules/homeModules/users/<user>/profile.nix` for packages, flatpaks, and session variables

### 3) Wrapped programs and wrappers
WIP (to be documented during onboarding pass).
