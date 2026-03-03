# PRD: Dendritic NixOS + Home Manager Baseline
Version: `1.0`
Status: Active baseline specification

## 1. Product Definition
This repository is a minimal, reproducible NixOS configuration built with the dendritic pattern:
1. one host: `bare`
2. one user: `bob`
3. Home Manager integrated through NixOS
4. explicit module selection by host and user modules
5. wrappers implemented with `wrappers` only

This PRD is an authoritative description of the current implementation and is intended to be sufficient to recreate it.

## 2. Platform and Scope
1. Platform is `x86_64-linux` only.
2. Composition core is `flake-parts`.
3. Module discovery is recursive through `import-tree` over `./modules`.
4. The baseline is intentionally small and contains only what is needed for `bare` + `bob`.

## 3. Flake Inputs
The flake must define these inputs:
1. `nixpkgs` (`nixos-unstable`)
2. `flake-parts`
3. `import-tree`
4. `home-manager` (follows `nixpkgs`)
5. `wrappers` (follows `nixpkgs`)
6. `treefmt-nix` (follows `nixpkgs`)

## 4. Flake Entrypoint
`flake.nix` remains thin and only:
1. declares inputs
2. calls `inputs.flake-parts.lib.mkFlake { inherit inputs; }`
3. passes `(inputs.import-tree ./modules)`

No host composition logic lives directly in `flake.nix`.

## 5. Output Model
The module tree must produce:
1. `nixosConfigurations.bare`
2. `nixosModules.base`
3. `nixosModules.userBob`
4. `nixosModules.hostBare`
5. `homeModules.userBob`
6. per-system wrapped packages:
   1. `packages.<system>.fish`
   2. `packages.<system>.fish-env`
   3. `packages.<system>.git`
   4. `packages.<system>.jj`

## 6. Module Contracts

### 6.1 flake-parts module
`modules/flake-parts.nix` must define:
1. `systems = [ "x86_64-linux" ]`
2. treefmt integration via `inputs.treefmt-nix.flakeModule`
3. formatter set to `config.treefmt.build.wrapper`
4. Nix formatter `alejandra` enabled

### 6.2 NixOS core module
`modules/nixosModules/core/base.nix` must define system-level baseline:
1. GRUB enabled with `devices = [ "nodev" ]`
2. root filesystem as `tmpfs`
3. `security.sudo.enable = true`

### 6.3 NixOS user module
`modules/nixosModules/users/bob.nix` must define:
1. `users.users.bob.isNormalUser = true`
2. primary group `bob`
3. extra groups include `wheel`
4. `users.groups.bob = {}`

### 6.4 Host module
`modules/nixosModules/hosts/bare/configuration.nix` must:
1. export `flake.nixosConfigurations.bare`
2. define `flake.nixosModules.hostBare`
3. import:
   1. `inputs.home-manager.nixosModules.home-manager`
   2. `self.nixosModules.base`
   3. `self.nixosModules.userBob`
4. set `networking.hostName = "bare"`
5. set `system.stateVersion = "24.11"`
6. enable HM integration with:
   1. `home-manager.useGlobalPkgs = true`
   2. `home-manager.useUserPackages = true`
7. wire wrapped packages through `home-manager.extraSpecialArgs.wrappedPrograms`
8. wire `home-manager.users.bob.imports = [ self.homeModules.userBob ]`
9. set HM defaults:
   1. `home.username = "bob"` (default)
   2. `home.homeDirectory = "/home/bob"` (default)

### 6.5 Host hardware module
`modules/nixosModules/hosts/bare/hardware-configuration.nix` must set:
1. `nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux"`

### 6.6 Home Manager user module
`modules/homeModules/users/bob.nix` must:
1. export `flake.homeModules.userBob`
2. import shared HM module path `home/shell/fish-env.nix`
3. set `home.stateVersion = "24.11"`
4. set `programs.home-manager.enable = true`

### 6.7 Shared HM shell module
`home/shell/fish-env.nix` must:
1. enable `programs.fish`
2. set `programs.fish.package = wrappedPrograms.fish`
3. install `wrappedPrograms.fish-env` in `home.packages`

### 6.8 Wrapped programs modules
`modules/wrappedPrograms/*.nix` must export per-system packages using `wrappers.lib.wrapPackage`:
1. `fish` wraps `pkgs.fish` with zoxide runtime init
2. `git` wraps `pkgs.git`
3. `jj` wraps `pkgs.jj` or falls back to `pkgs.jujutsu`
4. `fish-env` is a `pkgs.buildEnv` bundle that includes common CLI tools plus wrapped `git` and `jj`

## 7. Repository Layout
```text
.
├── flake.nix
├── modules
│   ├── flake-parts.nix
│   ├── nixosModules
│   │   ├── core/base.nix
│   │   ├── users/bob.nix
│   │   └── hosts/bare
│   │       ├── configuration.nix
│   │       └── hardware-configuration.nix
│   ├── homeModules
│   │   └── users/bob.nix
│   └── wrappedPrograms
│       ├── fish.nix
│       ├── fish-env.nix
│       ├── git.nix
│       └── jj.nix
├── home
│   └── shell/fish-env.nix
├── scripts
│   ├── fmt.sh
│   ├── check.sh
│   ├── check-vm.sh
│   └── switch.sh
└── justfile
```

## 8. Command Surface
The interface is:
1. `just fmt`
2. `just check`
3. `just check-vm`
4. `just switch host=<host>`

`justfile` contains routing only. Execution logic lives in `/scripts`.

## 9. Verification Policy
For this machine (already configured), do not use `just switch` during routine validation.

Required verification flow:
1. `just fmt`
2. `just check`
3. `just check-vm`

`just check-vm` must build:
1. `.#nixosConfigurations.bare.config.system.build.toplevel`
2. `.#nixosConfigurations.bare.config.system.build.vm`

## 10. Non-goals
1. No standalone `homeConfigurations` output.
2. No `switch-home` command.
3. No `wrapper-modules`.
4. No toggle-file/module-ID/unique-group policy framework.
5. No hidden global auto-application of all NixOS modules to a host or all HM modules to a user.

## 11. Acceptance Criteria
1. `flake.nix` remains thin and delegates to `import-tree ./modules`.
2. `nixosConfigurations.bare` evaluates successfully.
3. Home Manager functions only through NixOS integration.
4. User `bob` is present and has `wheel`.
5. Wrapped packages are built from `wrappers` only.
6. `just check` passes.
7. `just check-vm` passes without switching the live system.

---
Authorship attribution: `casper` (fresh baseline prose), `velma` (consistency and correctness pass), `dexter` (architecture constraints).
