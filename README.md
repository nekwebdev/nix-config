# nixos-v3 Bare Configuration

Minimal dendritic NixOS + Home Manager setup, modeled after the `nixconf` composition style:

- `flake.nix` stays thin: `mkFlake + import-tree ./modules`.
- everything under `modules/` is a flake-parts module.
- host modules explicitly import the NixOS modules they want.
- user modules explicitly import the HM modules they want.
- Home Manager is integrated through NixOS only.
- wrapped programs use `wrappers` only.

## Layout

- `modules/flake-parts.nix`: shared flake-parts settings (`systems`, treefmt).
- `modules/nixosModules/*`: exported NixOS modules and hosts.
- `modules/homeModules/*`: exported Home Manager user profiles.
- `home/*`: shared Home Manager modules imported by user profiles.
- `modules/wrappedPrograms/*`: per-system wrapped packages.

## Commands

```bash
just fmt
just check
just check-vm
just switch host=bare
just new-user user=alice
just new-host host=laptop user=alice
```

`just check-vm` is the preferred final validation on this machine because it builds `toplevel` and VM artifacts without switching the running host.
