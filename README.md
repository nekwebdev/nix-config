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
- `configs/common/*`: global fallback runtime config defaults.
- `configs/users/<user>/common/*`: per-user runtime config defaults.
- `configs/users/<user>/hosts/<host>/*`: per-user host-specific runtime config overrides.
- `modules/wrappedPrograms/*`: per-system wrapped packages.
- `secrets/*`: encrypted SOPS files (track in git).

## Commands

```bash
just fmt
just check
just check-vm
just switch <host>
just update
just new-user <user>
just new-user <user> ~/.ssh/id_ed25519
just new-host <host> <user>
just new-host <host> <user> sops_key_path=~/.ssh/id_ed25519
just sops-user-password <user>
just config-update
```

`just check-vm` is the preferred final validation on a 3rd party machine because it builds `toplevel` and VM artifacts without switching the running host.
`just config-update` updates the active layered runtime config sources in `configs/users/<user>/{common,hosts/<host>}` from the current system state.

For `<host>`/`<user>` password secrets, see [secrets/README.md](./secrets/README.md).

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
WIP (to be documented during onboarding pass).

### 4) Wrapped programs and wrappers
WIP (to be documented during onboarding pass).

## Future TODO

- Add a helper script to securely fetch per-user SSH keypairs from Vaultwarden and install them into `~/.ssh` before rebuild/switch.
- Add a `just help` command that documents all recipes, parameters, and common examples.
