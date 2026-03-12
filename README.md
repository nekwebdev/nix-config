# nixos Configuration

Minimal dendritic NixOS + Home Manager setup:

- `flake.nix` stays thin: `mkFlake + import-tree ./modules`.
- everything under `modules/` is a flake-parts module.
- host modules explicitly import the NixOS modules they want.
- user modules explicitly import the Home Manager modules they want.
- Home Manager is integrated through NixOS only.
- wrapped programs use `wrappers` only.

## Layout

- `modules/flake-parts.nix`: shared flake-parts settings (`systems`, treefmt).
- `modules/nixosModules/*`: exported NixOS modules and hosts.
- `modules/homeModules/*`: exported Home Manager user profiles.
- `modules/homeModules/users/<user>/<profile>.nix`: user profile entry modules (baseline: `users/oj/niri.nix`).
- `configs/common/*`: global fallback runtime config defaults.
- `configs/users/<user>/common/*`: per-user runtime config defaults.
- `configs/users/<user>/common/nordvpn/*.ovpn`: declarative NordVPN source profiles (imported into NetworkManager).
- `configs/users/<user>/hosts/<host>/*`: per-user host-specific runtime config overrides.
- `modules/wrappedPrograms/*`: per-system wrapped packages.
- `secrets/*`: encrypted SOPS files (track in git).

## Commands

```bash
just help
just fmt
just check
just check-vm
just switch host=<host>
just update
just new-user user=<user>
just new-user user=<user> sops_key_path=~/.ssh/id_ed25519
just new-host host=<host> user=<user>
just new-host host=<host> user=<user> sops_key_path=~/.ssh/id_ed25519
just sops-vpn-credentials
just vaultwarden-keys user=<user> host=<host> age_item=<age_item> ssh_item=<ssh_item>
just config-update
```

## Deployment Guides

- fresh install from a live ISO: [docs/install-new-system.md](/home/oj/.config/nixos/docs/install-new-system.md)
- changes on an existing host: [docs/deploy-existing-system.md](/home/oj/.config/nixos/docs/deploy-existing-system.md)

`just check-vm` is the preferred final validation on a 3rd party machine because it builds `toplevel` and VM artifacts without switching the running host.
`just config-update` updates the active layered runtime config sources in `configs/users/<user>/{common,hosts/<host>}` from the current system state.
For SOPS-backed VPN credentials, see [secrets/README.md](./secrets/README.md).

## NordVPN OVPN workflow

1. Put `.ovpn` files in:
   - `configs/users/<user>/common/nordvpn/`
2. Encrypt shared NordVPN credentials:

```bash
just sops-vpn-credentials
```

3. Rebuild:

```bash
just check
```

At evaluation time, each `.ovpn` in that folder is converted into a declarative NetworkManager VPN profile and all of them reuse `vpn/nordvpn-username` + `vpn/nordvpn-password`.

## Password bootstrap behavior

- User modules use a temporary bootstrap password hash (`changeme`) for first account creation.
- A fish reminder is shown until `passwd` succeeds once in fish.

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
WIP (to be documented during onboarding pass).

### 3) Secrets workflow

Use this for first-install key bootstrap from Vaultwarden in a fresh ISO shell.

1. Install/unlock Bitwarden CLI (`bw`) in the live environment:

```bash
bw login --apikey    # or bw login
export BW_SESSION="$(bw unlock --raw)"
```

2. Ensure two Vaultwarden items exist and store key material in item **notes**:
- `<age_item>` notes: full age key file content (`keys.txt`, including `AGE-SECRET-KEY-...`)
- `<ssh_item>` notes: SSH private key content for host signing/auth

3. Fetch and stage keys into the target install root:

```bash
just vaultwarden-keys <user> <host> <age_item> <ssh_item>
```

Optional:
- set target root (default `/mnt`): `... target_root=/mnt`
- set Vaultwarden server URL: `... server=https://vault.example.com`

The script writes:
- `<target_root>/home/<user>/.config/sops/age/keys.txt`
- `<target_root>/home/<user>/.ssh/nixos-<host>`
- `<target_root>/home/<user>/.ssh/nixos-<host>.pub`

It also prints an install hint using:
- `SOPS_AGE_KEY_FILE=<target_root>/home/<user>/.config/sops/age/keys.txt`

### 4) Wrapped programs and wrappers
WIP (to be documented during onboarding pass).
