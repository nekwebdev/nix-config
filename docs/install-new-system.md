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

On the NixOS live ISO, use the split Disko + `nixos-install` flow. This mounts the target SSD before the full NixOS build, so the build uses `/mnt/nix/store` instead of exhausting the live ISO's RAM-backed `/nix/.rw-store`.

First wipe, format, and mount the target disk:

```bash
sudo nix --extra-experimental-features 'nix-command flakes' \
  run 'github:nix-community/disko/latest#disko' -- \
  --mode destroy,format,mount \
  --flake "path:$PWD#aura" \
  --root-mountpoint /mnt \
  --yes-wipe-all-disks
```

Then confirm the target is mounted:

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS
findmnt -R /mnt
df -h /mnt/nix /mnt/persistent
```

Copy install-time persistent files:

```bash
sudo install -D -m 600 /tmp/aura-passwd /mnt/persistent/passwd

sudo install -d -m 700 /mnt/persistent/home/oj/.ssh
sudo install -m 600 ~/.ssh/aura /mnt/persistent/home/oj/.ssh/nixos-aura
sudo install -m 644 ~/.ssh/aura.pub /mnt/persistent/home/oj/.ssh/nixos-aura.pub
sudo install -m 600 ~/.ssh/nixos-sops /mnt/persistent/home/oj/.ssh/nixos-sops

sudo install -d -m 755 /mnt/persistent/home/oj/.config
sudo cp -a ~/.config/nixos /mnt/persistent/home/oj/.config/
```

Install NixOS into the mounted target:

```bash
sudo nixos-install \
  --root /mnt \
  --flake "path:$PWD#aura" \
  --no-root-passwd \
  --no-channel-copy \
  --max-jobs 1 \
  --cores 2 \
  --show-trace \
  --option eval-cache false \
  2>&1 | tee /tmp/aura-nixos-install.log
```

Fix ownership on the copied persistent user files:

```bash
sudo nixos-enter --root /mnt -c '
chown -R oj:oj /persistent/home/oj/.ssh /persistent/home/oj/.config/nixos
chmod 700 /persistent/home/oj/.ssh
chmod 600 /persistent/home/oj/.ssh/nixos-aura /persistent/home/oj/.ssh/nixos-sops
chmod 644 /persistent/home/oj/.ssh/nixos-aura.pub
'
```

If `nixos-install` fails after Disko has mounted the target, rerun the `nixos-install` step. Do not rerun Disko unless you intentionally want to wipe and recreate the target filesystems again.

If you intentionally need a disk other than `/dev/nvme0n1`, update the Aura Disko device first and revalidate before running the destructive Disko command.

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
2. The split install flow copies the repo to:

```text
/home/oj/.config/nixos
```

If it is missing, clone it there manually.

3. Confirm the Aura Git signing SSH key exists:

```bash
chmod 600 ~/.ssh/nixos-aura
chmod 644 ~/.ssh/nixos-aura.pub
```

The `ojAuraProfile` Git signing key path is `/home/oj/.ssh/nixos-aura`. Aura preservation keeps `~/.ssh`, so this survives reboot once placed on the installed system.

4. Confirm the SOPS age SSH identity exists if you want Aura ready to edit/decrypt repo secrets later:

```bash
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
