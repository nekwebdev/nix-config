# Lotus DMS/Niri Migration Decision Record

Scope: `host=lotus`, `user=oj`
Status: accepted for implementation
Updated: 2026-03-03

## Goals
- Migrate legacy DMS + Niri behavior from `~/.config/nixos` into this repo.
- Keep repository contracts intact: host/user explicit composition, HM through NixOS, no selector/profile framework.
- Ship migration in thin vertical slices that stay reviewable and buildable.

## Inputs and module strategy
Selected approach:
- Add flake inputs for:
  - `niri` (`github:sodiboo/niri-flake`)
  - `dms` (`github:AvengeMedia/DankMaterialShell`)
  - `dms-plugin-registry` (`github:AvengeMedia/dms-plugin-registry`)
- Keep `flake.nix` thin (inputs + `mkFlake` + `import-tree`) and keep all behavior in `modules/*`.

Reason:
- Legacy config depends on upstream module providers for both system and HM integration.
- Re-implementing those modules locally would be higher risk and slower than consuming upstream modules as originally configured.

## Composition model
NixOS host integration (system-level exceptions):
- Add `modules/nixosModules/hosts/lotus/niri.nix`:
  - `programs.niri.enable = true`
  - `systemd.user.services.niri-flake-polkit.enable = false`
  - overlay `niri.overlays.niri`, set `programs.niri.package = pkgs.niri-unstable`
  - `environment.sessionVariables.NIXOS_OZONE_WL = "1"`
- Add `modules/nixosModules/hosts/lotus/dms-greeter.nix`:
  - `programs.dank-material-shell.greeter.enable = true`
  - `services.displayManager.defaultSession = "niri"`
  - GNOME keyring + PAM keyring unlock for `login` and `greetd`
  - `/etc/greetd/niri_overrides.kdl` from legacy lotus override block

Home Manager integration (user-level):
- Keep all user-scoped DMS/Niri behavior in `modules/homeModules/users/oj.nix` under `isLotus`.
- Import upstream HM modules directly in `userOj`:
  - `inputs.dms.homeModules.dank-material-shell`
  - `inputs.dms.homeModules.niri`
  - `inputs.dms-plugin-registry.modules.default`
- Port non-selector behavior only:
  - DMS settings and plugin wiring
  - Matugen template activation script
  - Niri HM packages and `programs.niri.settings` baseline
  - Host files from legacy lotus `home/dms` and `home/niri` where still needed

## Explicit non-goals
- Do not reintroduce `my.context`, selector gates, or profile-based enablement.
- Do not add standalone Home Manager outputs.
- Do not move DMS/Niri user settings into NixOS except privileged host/session plumbing.

## Planned commit slices
1. `design` slice (this record)
- Acceptance:
  - migration approach and boundaries are explicit
  - next implementation commits are deterministic

2. `system` slice
- Add lotus host NixOS modules for `niri` and `dms-greeter`.
- Wire them in `modules/nixosModules/hosts/lotus/configuration.nix`.
- Validate:
  - `just fmt`
  - `just check`
  - `just check-vm`
  - `nix build .#nixosConfigurations.lotus.config.system.build.toplevel`

3. `home` slice
- Add DMS/Niri HM imports + settings + activation in `userOj`.
- Port required DMS/Niri user files/config payloads.
- Validate with the same gate and lotus build.

4. `closure` slice
- Remove redundant/obsolete bits found during migration.
- Update `README.md` and `PRD.md` only if contracts changed.
- Re-run validation gate.
