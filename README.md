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
- `configs/*`: repo-tracked app/runtime config sources synced to `~/.config/*` by module activation helpers.
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
just new-user <user>
just new-user <user> ~/.ssh/id_ed25519
just new-host <host> <user>
just new-host <host> <user> sops_key_path=~/.ssh/id_ed25519
just sops-user-password <user>
just config-update
```

`just check-vm` is the preferred final validation on a 3rd party machine because it builds `toplevel` and VM artifacts without switching the running host.
`just config-update` updates the config files in `configs/*` to match the current state of the system.

For `<host>`/`<user>` password secrets, see [secrets/README.md](./secrets/README.md).

## Future TODO

- Add a helper script to securely fetch per-user SSH keypairs from Vaultwarden and install them into `~/.ssh` before rebuild/switch.
- Add a `just help` command that documents all recipes, parameters, and common examples.
