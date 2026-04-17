# Config Lifecycle and Mutability

This doc answers one question: for config files in this repo, what happens on `just switch`?

## Lifecycle Classes

| Class | Source of truth | What `just switch` does | Local runtime edits survive? |
| --- | --- | --- | --- |
| Runtime seed (bootstrap-only) | `configs/*` layered files | Copies file only when runtime target is missing | Yes |
| Runtime enforced copy | `configs/*` file | Reinstalls file every activation | No |
| Nix-managed immutable | Nix modules (`programs.*`, `home.file`, `xdg.configFile`) | Links/generated files from store each activation | Usually no (or activation conflict if replaced) |
| Nix-managed mutable | Nix module + activation merge/patch flow | Merges/patches declarative defaults into writable runtime file | Yes |

## `configs/` in This Repo Today

### 1) Runtime seed (bootstrap-only)

Managed by `scripts/runtime-config-helper.sh seed <map>` via HM activation hooks in:
- `modules/homeModules/desktop/dms.nix` (`seed dms`)
- `modules/homeModules/desktop/niri.nix` (`seed niri`)

Behavior:
- Layer precedence: `configs/common` < `configs/users/<user>/common` < `configs/users/<user>/hosts/<host>`
- Copy only when target is missing (`copy_if_missing`)
- Existing runtime file is not overwritten on switch

Current files:
- `configs/users/oj/common/dms/settings.json` -> `~/.config/DankMaterialShell/settings.json`
- `configs/users/oj/common/dms/plugin_settings.json` -> `~/.config/DankMaterialShell/plugin_settings.json`
- `configs/users/oj/hosts/lotus/niri/*.kdl` -> `~/.config/niri/dms/*.kdl`

Pull-back:
- `just config-update` copies runtime changes back into layered repo files.
- `configs/users/*/hosts/*/niri/colors.kdl` is intentionally excluded from pull-back.

### 2) Runtime enforced copy (overwrite each switch)

Managed by `home.activation.dmsMatugenTemplates` in `modules/homeModules/desktop/dms.nix`.

Behavior:
- Activation removes old runtime file and installs repo version every switch.
- Runtime edits are overwritten on next switch.

Current files:
- `configs/common/matugen/config.toml` -> `~/.config/matugen/config.toml`
- `configs/common/matugen/templates/bat.tmTheme` -> `~/.config/matugen/templates/bat.tmTheme`
- `configs/common/matugen/templates/starship.toml` -> `~/.config/matugen/templates/starship.toml`
- `configs/common/matugen/templates/dank-zed-blurred.json` -> `~/.config/matugen/templates/dank-zed-blurred.json`

### 3) Nix-managed mutable (with repo baseline)

Current file:
- `configs/users/oj/common/zed/settings.json`

How it works:
- `modules/homeModules/programs/zed-editor.nix` reads this repo JSON into `programs.zed-editor.userSettings`.
- HM `programs.zed-editor.mutableUserSettings = true` keeps `~/.config/zed/settings.json` writable.
- On switch, HM merges dynamic runtime settings with declarative baseline (not hard overwrite).

Pull-back:
- `just config-update` includes `zed` map and copies `~/.config/zed/settings.json` back to `configs/users/<user>/common/zed/settings.json`.

## Nix-Managed Files Outside `configs/`

### 4) Nix-managed immutable examples

Example in current host:
- `~/.config/VSCodium/User/settings.json` is HM-managed from `modules/homeModules/programs/vscode.nix` (`programs.vscode.profiles.default.userSettings`).
- `~/.config/codex/memories/git-signing-preference.md` is HM-managed from `modules/homeModules/programs/codex.nix` (`xdg.configFile` source under `configs/common/codex/memories/`).

Behavior:
- Generated/linked from Nix store.
- Treat as declarative: edit Nix code, not runtime file.

### 5) Nix-managed mutable patch example

Example:
- `~/.vscode-oss/argv.json` via `home.activation.vscodeArgvPasswordStore` in `modules/homeModules/programs/vscode.nix`.

Behavior:
- Script creates file if missing.
- If file exists, script only inserts `"password-store":"gnome-libsecret"` when absent.
- Other user edits remain.

## Scaffolding Bootstrap vs Switch Behavior

Separate from runtime activation:
- `just new-user` bootstraps `configs/users/<user>/common/*` once from `scripts/templates/new-user/common/*`.
- `just new-host` bootstraps `configs/users/<user>/hosts/<host>/niri/*` once from `scripts/templates/new-host/niri/*`.

Those scaffolding steps create repo files once. Switch behavior after that follows class rules above.
