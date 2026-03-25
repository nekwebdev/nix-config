# Install on a New System

Use this flow from a NixOS live ISO to the first boot of a machine managed by this repo.

This guide is for a fresh machine install. For changes on an already-running host, use [deploy-existing-system.md](/home/oj/.config/nixos/docs/deploy-existing-system.md).

## Scope

Manual bootstrap covers:

- partitioning
- encryption
- filesystems
- mounts
- network access in the live environment

This repo takes over after the target root is mounted at `/mnt`.

## Prereqs

- boot a NixOS installer ISO
- connect networking
- have `git` available in the live environment
- optionally have `bw` available if you want to bootstrap age and SSH keys from Vaultwarden

## 1. Prepare the Disk

List disks:

```bash
lsblk -o NAME,SIZE,TYPE,LABEL
```

Choose the target disk. The examples below use `/dev/nvme1n1`.

Create a GPT partition table:

```bash
parted /dev/nvme1n1 -- mklabel gpt
```

Create a 1 GiB EFI partition:

```bash
parted /dev/nvme1n1 -- mkpart ESP fat32 1MiB 1025MiB
parted /dev/nvme1n1 -- set 1 esp on
mkfs.fat -F 32 -n EFI /dev/nvme1n1p1
```

Create an encrypted root partition using the rest of the disk:

```bash
parted /dev/nvme1n1 -- mkpart primary 1025MiB 100%
cryptsetup luksFormat /dev/nvme1n1p2
cryptsetup open /dev/nvme1n1p2 crypt-nix
mkfs.btrfs -L NIXROOT /dev/mapper/crypt-nix
```

Create Btrfs subvolumes:

```bash
mount /dev/mapper/crypt-nix /mnt

btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache

btrfs subvolume list /mnt
umount /mnt
```

Mount the target layout:

```bash
mount -o subvol=@root,compress=zstd,noatime /dev/mapper/crypt-nix /mnt
mkdir -p /mnt/{home,nix,var/log,var/cache,boot}

mount -o subvol=@home,compress=zstd,noatime /dev/mapper/crypt-nix /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/crypt-nix /mnt/nix
mount -o subvol=@log,compress=zstd,noatime /dev/mapper/crypt-nix /mnt/var/log
mount -o subvol=@cache,compress=zstd,noatime /dev/mapper/crypt-nix /mnt/var/cache
mount /dev/nvme1n1p1 /mnt/boot
```

Verify mounts:

```bash
mount | grep /mnt
```

The repo workflow starts here.

## 2. Generate Hardware Facts

Generate hardware config for the mounted target root:

```bash
nixos-generate-config --root /mnt
```

This writes a hardware file at:

```text
/mnt/etc/nixos/hardware-configuration.nix
```

Do not reuse `lotus` hardware settings blindly. Every new host needs its own `hardware-configuration.nix`.

## 3. Clone the Repo for Install-Time Use

Clone the repo into the target root:

```bash
git clone <repo-url> /mnt/etc/nixos
cd /mnt/etc/nixos
```

This install-time checkout is temporary. After first boot, keep the persistent working checkout at:

```text
/home/<user>/.config/nixos
```

## 4. Ensure the Host and User Exist in the Repo

If the host and user are already defined in the repo, skip this step.

If this is a new user:

```bash
just new-user user=<user>
```

If this is a new host:

```bash
just new-host host=<host> user=<user>
```

Scaffolding copies the baseline `oj` and `lotus` structure. It does not detect the new machine's hardware automatically.

After scaffolding a user, edit `modules/nixosModules/users/<user>.nix` for identity/admin settings and `modules/homeModules/users/<user>/profile.nix` for user packages and session config.

## 5. Replace the Scaffolded Hardware File

Copy the generated hardware config into the repo host path:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix \
  ./modules/nixosModules/hosts/<host>/hardware-configuration.nix
```

Then review it and make sure it matches your intended layout:

- LUKS device name: `crypt-nix`
- Btrfs subvolumes: `@root`, `@home`, `@nix`, `@log`, `@cache`
- mount points: `/`, `/home`, `/nix`, `/var/log`, `/var/cache`, `/boot`
- desired mount options such as `compress=zstd` and `noatime`

If the generated file misses your preferred Btrfs mount options, add them before install.

## 6. Install the System

Run the install from the repo root.

```bash
nixos-install --flake .#<host>
```

## 7. First Boot Follow-Up

After the machine boots into the installed system:

1. Clone the repo to `/home/<user>/.config/nixos`.
2. Run `just check`.
3. Run `just check-vm`.
4. Apply further changes with `just switch host=<host>`.

If you are working on Rust tooling or a Rust-based package in this repo later, enter the self-contained Rust shell with:

```bash
nix develop
# or
nix develop .#rust
```

## Notes

- This repo is `x86_64-linux` only.
- Home Manager is integrated through NixOS only.
- Do not validate a change on this machine with `just switch` during routine review. Use `just check` and `just check-vm`.
