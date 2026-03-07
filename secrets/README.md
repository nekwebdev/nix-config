# Secrets

This directory is for local encrypted SOPS files.

- Encrypted files in this directory should be tracked in git.
- Current VPN secret keys used by `networking.networkmanager.ensureProfiles`:
  - `vpn/nordvpn-username`
  - `vpn/nordvpn-password`
- These credentials are shared across all NordVPN profiles loaded from:
  - `configs/users/<user>/common/nordvpn/*.ovpn`
- Per-user SOPS recipients live at `secrets/recipients/users/<user>.txt`.

## Recommended Recipient Model

For host/user secrets, standard practice is:

1. Use an age recipient.
2. Keep the age private key file outside git.
3. Ensure the target host has that key file at the configured path before rebuild/switch.

## Bootstrap `<user>` Recipient

Generate a new dedicated key (default):

```bash
just new-user <user>
```

Use an existing recipients file:

```bash
just new-user <user> secrets/recipients/users/<user>.txt
```

The script writes:

- `secrets/recipients/users/<user>.txt` (tracked recipient metadata)
- expected target key path metadata for deployment

## Vaultwarden Key Bootstrap (fresh install)

Use this when installing from a live ISO and you want age + ssh keys staged into the target root before install.

Prereqs:
1. Bitwarden CLI (`bw`) is installed
2. Vault session is unlocked (`BW_SESSION` exported)
3. Vault items contain key material in item notes:
   - `age_item`: full age `keys.txt` content
   - `ssh_item`: SSH private key content

Run from repo root:

```bash
just vaultwarden-keys <user> <host> <age_item> <ssh_item>
```

Default target root is `/mnt`. Override if needed:

```bash
just vaultwarden-keys <user> <host> <age_item> <ssh_item> target_root=/mnt
```

## Bootstrap VPN credentials secret

```bash
just sops-vpn-credentials
git add secrets/vpn.yaml
```

Then ensure your NordVPN `.ovpn` files are present:

```bash
ls configs/users/<user>/common/nordvpn/*.ovpn
```

Then rebuild:

```bash
just check
```
