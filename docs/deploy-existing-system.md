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
sudo nixos-rebuild switch --flake .#<host>
```

## Adding a New User or Host

Use the scaffolding commands first:

```bash
just new-user user=<user>
just new-host host=<host> user=<user>
```

Then edit the generated modules and configs.

For a new host, replace the scaffolded hardware file with hardware data generated on the real machine before install or switch.

## Secrets

If the host uses SOPS secrets, make sure the expected key files exist at the paths referenced by the user and host modules before switching.

Vaultwarden bootstrap on an already-running system:

```bash
just vaultwarden-keys user=<user> host=<host> age_item=<age-item> ssh_item=<ssh-item> target_root=/
```

## Runtime Config Sync

If you changed a UI-managed app config on the live system and want to pull it back into the repo:

```bash
just config-update
```

## Notes

- Use `just check` and `just check-vm` as the default validation path.
- Keep `flake.lock` updates intentional.
- This repo does not support standalone Home Manager deployment.
