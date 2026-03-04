# Secrets

This directory is for local encrypted SOPS files.

- Encrypted files in this directory should be tracked in git.
- Current password secret key used by `<host>`/`<user>`: `users/<user>-password`.
- Per-user SOPS recipients live at `secrets/recipients/users/<user>.txt`.

## Recommended Recipient Model

For NixOS user-password secrets, standard practice is:

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

## Bootstrap `<user>` password secret

```bash
just sops-user-password <user>
git add secrets/users.yaml
```

Then rebuild:

```bash
just check
```
