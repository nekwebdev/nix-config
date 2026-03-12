# VPN OVPN Profiles

Put provider `.ovpn` files in this directory.

- Each `.ovpn` file is imported by `vpn-profile-import` into NetworkManager.
- The profile name is the filename without `.ovpn`.
- All generated profiles share the same SOPS credentials:
  - `vpn/username`
  - `vpn/password`

Notes:
- Keep OpenVPN-style configs here (`auth-user-pass`, inline `<ca>`, inline `<tls-auth>`).
- `.ovpn` files are user-supplied and gitignored.
- Keep `.gitkeep` so this directory remains in the repo.
