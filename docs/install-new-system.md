# Install on a New System

Use this flow from a NixOS live ISO to the first boot of a machine managed by this repo.

For changes on an already-running host, use [deploy-existing-system.md](deploy-existing-system.md).

## Scope

There are two install paths:

- `aura`: use the repo's Disko + preservation configuration.
- generic scaffolded hosts: partition manually or add a host-specific Disko module first.

Aura is the only host in this repo currently designed for declarative full-disk install.

## Prereqs

- boot a NixOS installer ISO
- connect networking
- have `git` available in the live environment
- have the repo accessible over SSH or HTTPS
- know the target disk name from `lsblk`

For Aura, the intended disk is the internal NVMe drive, currently modeled as `/dev/nvme0n1`.

## 1. Clone the Repo

The clone location in the live ISO does not matter. This repo normally lives at `/home/oj/.config/nixos` after install, but during install it can live anywhere writable.

Example:

```bash
mkdir -p ~/.config
git clone <repo-url> ~/.config/nixos
cd ~/.config/nixos
```

## 2. Verify Target Hardware

List disks and confirm the target:

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS
```

For Aura, confirm `/dev/nvme0n1` is the disk you intend to wipe.

Also compare generated hardware facts:

```bash
nixos-generate-config --no-filesystems --flake --dir /tmp/aura-generated-hw
```

Compare `/tmp/aura-generated-hw/hardware-configuration.nix` with:

```text
modules/nixosModules/hosts/aura/hardware-configuration.nix
```

For Aura, filesystem declarations intentionally come from Disko and preservation, not from generated filesystem entries.

## 3. Validate Before Disk Changes

From the repo root:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  --option eval-cache false \
  flake check --impure --no-build --show-trace -L "path:$PWD"
```

For a narrower Aura check:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  eval --raw --impure \
  "path:$PWD#nixosConfigurations.aura.config.system.build.toplevel.drvPath"
```

## 4. Aura Disko Install

Warning: this destroys the target disk. The Aura Disko module defines a full-disk GPT layout with:

- 1 GiB EFI system partition mounted at `/boot`
- LUKS container named `crypt-aura`
- Btrfs filesystem labeled `AURA`
- `/nix` and `/persistent` Btrfs subvolumes
- tmpfs root `/`
- disk-backed `/tmp` under preservation, cleared on boot
- disk-backed `/var/tmp` under preservation, kept across boot
- 32 GiB swapfile at `/persistent/swapfile`, created by NixOS on first boot/switch

Create the installed `oj` password hash in the live ISO:

```bash
mkpasswd -m yescrypt > /tmp/aura-passwd
chmod 600 /tmp/aura-passwd
```

The Disko module is:

```text
modules/nixosModules/hosts/aura/disko.nix
```

Use `disko-install` so partitioning, formatting, mounting, and `nixos-install` run from the flake:

```bash
sudo nix --extra-experimental-features 'nix-command flakes' \
  run 'github:nix-community/disko/latest#disko-install' -- \
  --flake "path:$PWD#aura" \
  --disk main /dev/nvme0n1 \
  --extra-files /tmp/aura-passwd /persistent/passwd
```

If you intentionally need a different disk, change only the final device path. `--disk main ...` overrides `disko.devices.disk.main.device` for the install.

## 5. Generic Non-Aura Install

For a new non-Aura host, scaffold first:

```bash
just new-user user=<user>
just new-host host=<host> user=<user>
```

Then either:

- add a host-specific Disko module and install with `disko-install`, or
- manually partition/mount the target at `/mnt`, run `nixos-generate-config --root /mnt`, copy the generated hardware file into `modules/nixosModules/hosts/<host>/hardware-configuration.nix`, and install with:

```bash
sudo nixos-install --flake "path:$PWD#<host>"
```

Do not reuse `lotus` or `aura` hardware settings blindly. Every host needs reviewed hardware facts.

## 6. First Boot Follow-Up

After Aura boots into the installed system:

1. Log in as `oj` with the password used for `/tmp/aura-passwd`.
2. Clone the repo to:

```text
/home/oj/.config/nixos
```

3. Restore the Aura Git signing SSH key:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp /path/to/private/key ~/.ssh/nixos-aura
cp /path/to/public/key ~/.ssh/nixos-aura.pub
chmod 600 ~/.ssh/nixos-aura
chmod 644 ~/.ssh/nixos-aura.pub
```

The `ojAuraProfile` Git signing key path is `/home/oj/.ssh/nixos-aura`. Aura preservation keeps `~/.ssh`, so this survives reboot once placed on the installed system.

4. Restore the SOPS age SSH identity if you want Aura ready to edit/decrypt repo secrets later:

```bash
cp /path/to/nixos-sops ~/.ssh/nixos-sops
chmod 600 ~/.ssh/nixos-sops
```

The SOPS public key is not needed on the machine for decryption. Aura preserves this key in `~/.ssh`, but the current Aura system does not consume SOPS secrets during activation.

5. Validate and switch from the installed checkout:

```bash
cd ~/.config/nixos
just check
just check-vm host=aura
just switch host=aura
```

## Aura Preservation Notes

Aura uses `preservation` with `/persistent` as the persistence root. The installed root filesystem is intentionally volatile.

Preserved state includes:

- `/etc/machine-id`
- SSH host keys
- `/tmp`, backed by `/persistent/tmp` and cleared on boot
- `/var/tmp`, backed by `/persistent/var/tmp` and kept across boot
- 32 GiB swapfile at `/persistent/swapfile`
- NetworkManager, Bluetooth, Flatpak, fwupd, printing, Tailscale, logs, random seed, backlight/rfkill, and related system state
- `oj` user state such as `.ssh`, `.config/codex`, browser/editor data, Niri/DMS runtime config, VPN profiles, shell/tool state, Steam, keyrings, and standard user directories

Aura intentionally does not preserve `.config/claude` because Aura does not import the Claude module.

## Notes

- This repo is `x86_64-linux` only.
- Home Manager is integrated through NixOS only.
- Do not validate a change on this machine with `just switch` during routine review. Use `just check` and `just check-vm host=<host>`.
