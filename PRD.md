# PRD: Dendritic NixOS + Home Manager Pattern
Version: `1.26`
Status: Active specification

## 1. Product Definition
This repository defines a minimal but extensible NixOS configuration pattern:
1. ship a working baseline host `lotus`
2. ship a working baseline user `oj`
3. support additional hosts/users through boilerplate scaffolding commands
4. keep host and user composition explicit and reviewable

The baseline (`lotus` + `oj`) is the reference implementation. New hosts/users must follow the same design contracts.

## 2. Platform and Scope
1. Platform is `x86_64-linux` only.
2. Composition core is `flake-parts`.
3. Module discovery is recursive through `import-tree` over `./modules`.
4. Home Manager integration is through NixOS only (no standalone HM output path).

## 3. Flake Inputs
The flake must define these inputs:
1. `nixpkgs` (`nixos-unstable`)
2. `flake-parts`
3. `import-tree`
4. `home-manager` (follows `nixpkgs`)
5. `wrappers` (optional; follows `nixpkgs`; reserved for future wrapped binaries)
6. `treefmt-nix` (follows `nixpkgs`)
7. `nix-monitor` (follows `nixpkgs`)

## 4. Flake Entrypoint
`flake.nix` remains thin and only:
1. declares inputs
2. calls `inputs.flake-parts.lib.mkFlake { inherit inputs; }`
3. passes `(inputs.import-tree ./modules)`

No host/user composition logic lives directly in `flake.nix`.

## 5. Output Model
### 5.1 Baseline outputs (required)
1. `nixosConfigurations.lotus`
2. `nixosModules.system`
3. `nixosModules.userOj`
4. `nixosModules.hostLotus`
5. `homeModules.ojProfile`
6. `homeModules.base`
7. `homeModules.fish`
8. `homeModules.aliasRegistry`
9. `homeModules.aliasesCommon`
10. `homeModules.environment`
11. `homeModules.git`

### 5.2 Extensible pattern outputs
For each scaffolded user `<user>`:
1. `nixosModules.user<User>`
2. `homeModules.<user>Profile` (default scaffolded profile)

For each scaffolded host `<host>` bound to user `<user>`:
1. `nixosConfigurations.<host>`
2. `nixosModules.host<Host>`
3. host module imports `self.nixosModules.user<User>`
4. host HM wiring imports `self.homeModules.<user>Profile`

`<User>` and `<Host>` follow scaffold naming (`[a-z][a-z0-9]*` input, first letter capitalized for module names).

### 5.3 Wrapped package scaffolding (reserved)
1. `modules/wrappedPrograms/` is reserved for future wrapper modules.
2. Current baseline does not require wrapper package outputs under `perSystem.packages.x86_64-linux`.
3. Default behavior should be expressed through explicit Home Manager modules.

### 5.4 Optional development shells
1. Optional language or environment shells may be exported under `devShells.<name>`.
2. Dev shells live in `modules/dev/*.nix`.
3. Dev shells are contributor environments, not replacements for `just` as the public runner.

## 6. Composition Contracts
### 6.1 flake-parts module (`modules/flake-parts.nix`)
1. `systems = [ "x86_64-linux" ]`
2. treefmt integration via `inputs.treefmt-nix.flakeModule`
3. formatter set to `config.treefmt.build.wrapper`
4. Nix formatter `alejandra` enabled

### 6.2 NixOS core module (`modules/nixosModules/core/base.nix`)
System-level baseline may include HM-first exceptions only:
1. boot/kernel/hardware
2. filesystems
3. networking/firewall
4. users/groups
5. PAM/sudo/polkit
6. root-owned services

Current baseline includes:
1. `security.sudo.enable = true`

### 6.3 NixOS user module contract (`modules/nixosModules/users/<user>.nix`)
Each host-declared user module must:
1. export `flake.nixosModules.user<User>`
2. define `my.users.<user>` as the typed user contract for host/HM wiring
3. set at least:
   1. `githubUsername`
   2. `email`
   3. `isAdmin`
   4. derived `extraGroups`
4. define a normal user (`isNormalUser = true`)
5. set primary group to `<user>`
6. include `wheel` in `extraGroups`
7. declare `users.groups.<user> = {}`
8. user `description` is optional and not required by this pattern

### 6.4 Home Manager user profile contract (`modules/homeModules/users/<user>/<profile>.nix`)
Each HM user profile module must:
1. export `flake.homeModules.<user><Profile>` (baseline profile export is `ojProfile`)
2. import shared HM modules explicitly (current baseline:
   1. `self.homeModules.base`
   2. `self.homeModules.fish`
   3. `self.homeModules.aliasRegistry`
   4. `self.homeModules.aliasesCommon`
   5. `self.homeModules.environment`
   6. `self.homeModules.git`)
3. set `home.stateVersion = "25.11"`
4. set `programs.home-manager.enable = true`
5. keep program-level behavior in focused reusable HM modules (for example `self.homeModules.bat`, `self.homeModules.eza`) and import them explicitly
6. `self.homeModules.base` is the shared user baseline and may include shared bootstrap reminder activation logic
7. user profile modules read identity from `osConfig.my.users.<user>` instead of hardcoding it locally
8. user profile modules may set user-specific packages, theme, flatpaks, and session values directly

### 6.5 Host module contract (`modules/nixosModules/hosts/<host>/configuration.nix`)
Each host configuration must:
1. export `flake.nixosConfigurations.<host>`
2. define `flake.nixosModules.host<Host>`
3. import:
   1. `inputs.home-manager.nixosModules.home-manager`
   2. required shared host feature modules (for example `self.nixosModules.system`)
   3. `self.nixosModules.user<User>`
4. set `networking.hostName = "<host>"`
5. set `system.stateVersion = "25.11"` either directly or via explicitly imported host-local modules in the same host stack
6. enable HM integration:
   1. `home-manager.useGlobalPkgs = true`
   2. `home-manager.useUserPackages = true`
7. pass only explicitly required HM args through `home-manager.extraSpecialArgs`; do not inject wrapper bundles by default
8. set `my.primaryUser = "<user>"`
9. derive HM wiring from `config.my.users.<user>`
10. set `home-manager.users.<user>.imports = [ self.homeModules.<user><Profile> ]` (baseline profile export is `<user>Profile`)
11. set HM defaults:
   1. `home.username = "<user>"` (default)
   2. `home.homeDirectory = "/home/<user>"` (default)
12. host-specific decomposition is explicit: `configuration.nix` may import shared feature modules (for example `self.nixosModules.system`, `self.nixosModules.policy`) exported from `modules/nixosModules/programs/`

### 6.6 Host hardware contract (`modules/nixosModules/hosts/<host>/hardware-configuration.nix`)
Each host hardware module must set:
1. `nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux"`

### 6.7 Wrapped programs policy (`modules/wrappedPrograms/`)
1. Wrapped programs are optional and are not part of baseline feature parity.
2. Module-first policy applies: if a program can be expressed through Home Manager modules, it must be.
3. If a wrapper is reintroduced, it must use `wrappers.lib.wrapPackage` with an explicit rationale.
4. Do not reintroduce bundled tool environments (for example `fish-env`).

### 6.8 Shared Home Manager module contracts (`modules/homeModules/shared/*.nix`)
1. `base.nix` exports `flake.homeModules.base`, provides shared must-have user packages, and carries shared password-bootstrap reminder activation logic.
2. `programs/fish.nix` exports `flake.homeModules.fish` and is responsible for fish enablement + fish shell behavior only.
3. `aliases.nix` exports `flake.homeModules.aliasRegistry`, defines `my.home.aliases.fragments`, merges aliases into all enabled shells (`bash`, `fish`, `zsh`), and hard-fails on duplicate alias keys.
4. `aliases-common.nix` exports `flake.homeModules.aliasesCommon` and provides baseline non-package aliases through `my.home.aliases.fragments`.
5. `environment.nix` exports `flake.homeModules.environment` and provides baseline `xdg.enable`, cross-shell session path, and baseline session variables.
6. `programs/git.nix` exports `flake.homeModules.git` and provides shared git behavior that is not identity-specific.

### 6.9 Reusable Home module naming
1. Reusable HM modules must be user-agnostic in both filename and exported name.
2. User-scoped HM profiles must be exported as flat names under `flake.homeModules` (`<user><Profile>`, for example `ojProfile`, `aliceProfile`).
3. Reusable HM modules should avoid duplicate basenames to keep tree reorganization non-semantic.
4. Reusable HM modules should live in category directories (for example `shared/`, `programs/`, `desktop/`) and export neutral names (for example `base`, `fish`, `environment`, `bat`, `eza`, `brave`, `fastfetch`, `fzf`, `ghostty`, `mangohud`, `nixMonitor`, `starship`, `tlrc`, `vscode`, `zedEditor`, `zoxide`, `dms`, `niri`).
5. User-scoped profile modules live under `modules/homeModules/users/<user>/` (for example `profile.nix`, `gaming.nix`).

### 6.10 Home module file layout and mutable runtime config policy
1. A module is either a single file (`<name>.nix`) or a folder (`<name>/<name>.nix`) with all module-local assets (templates, default configs, docs) colocated under that folder.
2. Prefer folder modules when a feature has supporting files that should travel with the module.
3. Use a hybrid HM + dotfiles model for app config management.
4. HM-first still applies: when program configuration is stable and not frequently changed by in-app UI, manage it declaratively through Home Manager modules.
5. If a program frequently rewrites config through UI interactions, manage that config as copy-synced runtime dotfiles instead of immutable HM store links.
6. Copy-synced runtime configs must use the repo helper flow:
   1. source of truth files use a three-tier layout:
      1. `configs/common/*` (global fallback defaults)
      2. `configs/users/<user>/common/*` (user defaults)
      3. `configs/users/<user>/hosts/<host>/*` (host-specific user overrides)
   2. seed precedence is `configs/common` < `configs/users/<user>/common` < `configs/users/<user>/hosts/<host>`
   3. `scripts/runtime-config-helper.sh seed <map>` copies the highest-precedence repo file for each tracked runtime file, only when runtime targets are missing
   4. `just config-update` (via `scripts/config-update.sh`) pulls runtime changes back into repo-tracked files for the active `<user>/<host>` scope
7. Mutable runtime configs must not be managed as read-only `xdg.configFile` store symlinks.
8. Pull exclusions are allowed for intentionally volatile files and must be declared in `scripts/runtime-config-helper.sh` as repo-relative paths.

### 6.11 Development shell module contracts (`modules/dev/*.nix`)
1. Each file under `modules/dev/` must itself be a valid flake-parts module.
2. Dev shells are optional and may export `perSystem.devShells.<name>`.
3. Dev shells should be self-contained for a language or environment, including the tools and helper commands that make the shell useful on its own.
4. `devShells.default` may point to one of the named shells with `lib.mkDefault`.
5. Dev shells do not replace `just` as the repo's public task runner.

## 7. Scaffolding and Naming
Scaffolding is the standard path for adding new entities:
1. `just new-user user=<user>` creates:
   1. `modules/nixosModules/users/<user>.nix`
   2. `modules/homeModules/users/<user>/base.nix`
   3. `modules/homeModules/users/<user>/profile.nix`
   4. `configs/users/<user>/common/` rendered from static baseline templates for runtime config parity
   5. user scaffolding is rendered from `scripts/templates/new-user/` with `<user>` placeholders
2. `just new-host host=<host> user=<user>` creates:
   1. `modules/nixosModules/hosts/<host>/configuration.nix`
   2. `modules/nixosModules/hosts/<host>/hardware-configuration.nix`
   3. `configs/users/<user>/hosts/<host>/` rendered from static host runtime-config templates
   4. host scaffolding is rendered from `scripts/templates/new-host/` with `<host>/<user>` placeholders
   5. generated hardware config is a placeholder that must be replaced with host-specific hardware data
3. generated HM user profile modules import:
   1. `self.homeModules.base`
   2. `self.homeModules.fish`
   3. `self.homeModules.aliasRegistry`
   4. `self.homeModules.aliasesCommon`
   5. `self.homeModules.environment`
   6. `self.homeModules.git`
4. after scaffolding:
   1. edit `modules/nixosModules/users/<user>.nix` for identity and admin settings
   2. edit `modules/homeModules/users/<user>/profile.nix` for packages, flatpaks, and session variables

Naming rules:
1. `<host>` and `<user>` must match `^[a-z][a-z0-9]*$`
2. scaffolded NixOS module suffixes are first-letter capitalized (`userAlice`, `hostLaptop`), while HM profile exports use flat concatenated names (`homeModules.<user>Profile`)
3. reusable HM modules must not carry a specific username in filename or export name

## 8. Command Surface
The supported interface is:
1. `just fmt`
2. `just check`
3. `just check-vm`
4. `just switch [host=<host>]`
5. `just new-user user=<user>`
6. `just new-host host=<host> user=<user>`
7. `just config-update`

`justfile` contains routing only. Execution logic lives in `/scripts`.

Optional contributor environment:
1. `nix develop`
2. `nix develop .#rust`

## 9. Verification Policy
Do not use `just switch` for routine validation on this already configured machine.

Required validation flow before merge:
1. `just fmt`
2. `just check`
3. `just check-vm`

`just check-vm` must build:
1. `.#nixosConfigurations.lotus.config.system.build.toplevel`
2. `.#nixosConfigurations.lotus.config.system.build.vm`

## 10. Non-goals
1. No standalone `homeConfigurations` output.
2. No `switch-home` command.
3. No `wrapper-modules`.
4. No toggle-file/module-ID/unique-group policy framework.
5. No hidden global auto-application of all NixOS modules to a host or all HM modules to a user.

## 11. Acceptance Criteria
1. `flake.nix` remains thin and delegates to `import-tree ./modules`.
2. Baseline `nixosConfigurations.lotus` evaluates successfully.
3. Home Manager functions through NixOS integration only.
4. Host-declared users are normal users and include `wheel`.
5. Program and tool behavior is modeled through explicit Home Manager modules (module-first), with wrappers reserved for exceptional future cases.
6. Scaffolding commands generate PRD-compliant module boilerplate without manual flake wiring.
7. `just check` passes.
8. `just check-vm` passes without switching the live system.
9. Mutable UI-driven runtime configs follow the layered copy-sync helper flow (`runtime-config-helper` + `just config-update`) instead of immutable HM store links.
10. First-install key bootstrap command stages age + host SSH keys into target user home for install-time and post-install usage.
