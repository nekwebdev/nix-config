# Deploy on an Existing NixOS System

Use this flow for changes on a machine that is already installed and already managed by this repo.

For first install from a live ISO, use [install-new-system.md](/home/oj/.config/nixos/docs/install-new-system.md).

## Working Location

Use a persistent checkout owned by the target user:

```text
/home/<user>/.config/nixos
```

Example:

```bash
cd /home/<user>/.config/nixos
```

If you are working on Rust tooling or a Rust-based package in this repo, use the self-contained Rust shell:

```bash
nix develop
# or
nix develop .#rust
```

## Standard Change Flow

Update the repo contents, then validate before switching:

```bash
just fmt
just check
just check-vm
```

Apply the configuration to the current machine:

```bash
just switch host=<host>
```

`just switch` runs:

```bash
sudo nixos-rebuild dry-activate --flake .#<host>
sudo nixos-rebuild test --flake .#<host>
sudo nixos-rebuild switch --flake .#<host>
```

## Adding a New User or Host

Use the scaffolding commands first:

```bash
just new-user user=<user>
just new-host host=<host> user=<user>
```

Then edit the generated modules and configs:

- `modules/nixosModules/users/<user>.nix` for identity and admin settings
- `modules/homeModules/users/<user>/profile.nix` for packages, flatpaks, and session variables

For a new host, replace the scaffolded hardware file with hardware data generated on the real machine before install or switch.

## Runtime Config Sync

If you changed a UI-managed app config on the live system and want to pull it back into the repo:

```bash
just config-update
```

## Notes

- Use `just check` and `just check-vm` as the default validation path.
- Keep `flake.lock` updates intentional.
- Keep the temporary NVIDIA CDI udev workaround in `modules/nixosModules/programs/nvidia.nix` until upstream nixpkgs fixes the trailing quote typo in `nixos/modules/services/hardware/nvidia-container-toolkit/default.nix`.
- On each input update (`just update` / `flake.lock` change), re-check upstream and remove the local override once the fix lands.
- This repo does not support standalone Home Manager deployment.
