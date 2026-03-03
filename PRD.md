# PRD: Dendritic NixOS + Home Manager Pattern
Version: `1.1`
Status: Active specification

## 1. Product Definition
This repository defines a minimal but extensible NixOS configuration pattern:
1. ship a working baseline host `bare`
2. ship a working baseline user `bob`
3. support additional hosts/users through boilerplate scaffolding commands
4. keep host and user composition explicit and reviewable

The baseline (`bare` + `bob`) is the reference implementation. New hosts/users must follow the same design contracts.

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
5. `wrappers` (follows `nixpkgs`)
6. `treefmt-nix` (follows `nixpkgs`)

## 4. Flake Entrypoint
`flake.nix` remains thin and only:
1. declares inputs
2. calls `inputs.flake-parts.lib.mkFlake { inherit inputs; }`
3. passes `(inputs.import-tree ./modules)`

No host/user composition logic lives directly in `flake.nix`.

## 5. Output Model
### 5.1 Baseline outputs (required)
1. `nixosConfigurations.bare`
2. `nixosModules.base`
3. `nixosModules.userBob`
4. `nixosModules.hostBare`
5. `homeModules.userBob`

### 5.2 Extensible pattern outputs
For each scaffolded user `<user>`:
1. `nixosModules.user<User>`
2. `homeModules.user<User>`

For each scaffolded host `<host>` bound to user `<user>`:
1. `nixosConfigurations.<host>`
2. `nixosModules.host<Host>`
3. host module imports `self.nixosModules.user<User>`
4. host HM wiring imports `self.homeModules.user<User>`

`<User>` and `<Host>` follow scaffold naming (`[a-z][a-z0-9]*` input, first letter capitalized for module names).

### 5.3 Per-system wrapped packages
`perSystem.packages.x86_64-linux` must export:
1. `fish`
2. `fish-env`
3. `git`
4. `jj`

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
1. GRUB with `devices = [ "nodev" ]`
2. root filesystem on `tmpfs`
3. `security.sudo.enable = true`

### 6.3 NixOS user module contract (`modules/nixosModules/users/<user>.nix`)
Each host-declared user module must:
1. export `flake.nixosModules.user<User>`
2. define a normal user (`isNormalUser = true`)
3. set primary group to `<user>`
4. include `wheel` in `extraGroups`
5. declare `users.groups.<user> = {}`

### 6.4 Home Manager user module contract (`modules/homeModules/users/<user>.nix`)
Each HM user module must:
1. export `flake.homeModules.user<User>`
2. import shared HM modules explicitly (current baseline: `self.homeModules.fishEnv` from `modules/homeModules/shared/fish-env.nix`)
3. set `home.stateVersion = "25.11"`
4. set `programs.home-manager.enable = true`

### 6.5 Host module contract (`modules/nixosModules/hosts/<host>/configuration.nix`)
Each host configuration must:
1. export `flake.nixosConfigurations.<host>`
2. define `flake.nixosModules.host<Host>`
3. import:
   1. `inputs.home-manager.nixosModules.home-manager`
   2. `self.nixosModules.base`
   3. `self.nixosModules.user<User>`
4. set `networking.hostName = "<host>"`
5. set `system.stateVersion = "25.11"`
6. enable HM integration:
   1. `home-manager.useGlobalPkgs = true`
   2. `home-manager.useUserPackages = true`
7. pass wrapped packages via `home-manager.extraSpecialArgs.wrappedPrograms`
8. set `home-manager.users.<user>.imports = [ self.homeModules.user<User> ]`
9. set HM defaults:
   1. `home.username = "<user>"` (default)
   2. `home.homeDirectory = "/home/<user>"` (default)

### 6.6 Host hardware contract (`modules/nixosModules/hosts/<host>/hardware-configuration.nix`)
Each host hardware module must set:
1. `nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux"`

### 6.7 Wrapped programs contract (`modules/wrappedPrograms/*.nix`)
Use `wrappers` only (`wrappers.lib.wrapPackage`):
1. `fish` wraps `pkgs.fish` with runtime init
2. `git` wraps `pkgs.git`
3. `jj` wraps `pkgs.jj` or falls back to `pkgs.jujutsu`
4. `fish-env` is a `pkgs.buildEnv` bundle including common CLI tools plus wrapped `git` and `jj`

## 7. Scaffolding and Naming
Scaffolding is the standard path for adding new entities:
1. `just new-user user=<user>` creates:
   1. `modules/nixosModules/users/<user>.nix`
   2. `modules/homeModules/users/<user>.nix`
2. `just new-host host=<host> user=<user>` creates:
   1. `modules/nixosModules/hosts/<host>/configuration.nix`
   2. `modules/nixosModules/hosts/<host>/hardware-configuration.nix`

Naming rules:
1. `<host>` and `<user>` must match `^[a-z][a-z0-9]*$`
2. scaffolded module suffixes are first-letter capitalized (`userAlice`, `hostLaptop`)

## 8. Command Surface
The supported interface is:
1. `just fmt`
2. `just check`
3. `just check-vm`
4. `just switch host=<host>`
5. `just new-user user=<user>`
6. `just new-host host=<host> user=<user>`

`justfile` contains routing only. Execution logic lives in `/scripts`.

## 9. Verification Policy
Do not use `just switch` for routine validation on this already configured machine.

Required validation flow before merge:
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
2. Baseline `nixosConfigurations.bare` evaluates successfully.
3. Home Manager functions through NixOS integration only.
4. Host-declared users are normal users and include `wheel`.
5. Wrapped packages are built from `wrappers` only.
6. Scaffolding commands generate PRD-compliant module boilerplate without manual flake wiring.
7. `just check` passes.
8. `just check-vm` passes without switching the live system.
