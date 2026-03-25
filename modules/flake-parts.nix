{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.treefmt-nix.flakeModule];

  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    description = "Home Manager modules exported by this flake.";
  };

  config = {
    systems = ["x86_64-linux"];

    perSystem = {
      config,
      pkgs,
      ...
    }: let
      mkScriptApp = {
        name,
        script,
        description,
        runtimeInputs ? [],
      }: {
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            inherit name runtimeInputs;
            text = ''
              exec ${pkgs.bash}/bin/bash ${script} "$@"
            '';
          }
        );
        meta.description = description;
      };

      helperApps = {
        help = mkScriptApp {
          name = "nixos-help";
          script = ../scripts/help.sh;
          description = "Show the repo's public just recipes.";
        };

        fmt = mkScriptApp {
          name = "nixos-fmt";
          script = ../scripts/fmt.sh;
          description = "Run treefmt via nix fmt.";
          runtimeInputs = [pkgs.nix];
        };

        check = mkScriptApp {
          name = "nixos-check";
          script = ../scripts/check.sh;
          description = "Run flake checks for this repo.";
          runtimeInputs = [pkgs.nix];
        };

        "check-vm" = mkScriptApp {
          name = "nixos-check-vm";
          script = ../scripts/check-vm.sh;
          description = "Build the configured system and VM targets.";
          runtimeInputs = [pkgs.nix];
        };

        "new-user" = mkScriptApp {
          name = "nixos-new-user";
          script = ../scripts/new-user.sh;
          description = "Scaffold a new user module set.";
          runtimeInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.gnused
          ];
        };

        "new-host" = mkScriptApp {
          name = "nixos-new-host";
          script = ../scripts/new-host.sh;
          description = "Scaffold a new host and its user-specific config.";
          runtimeInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.gnused
          ];
        };

        "config-update" = mkScriptApp {
          name = "nixos-config-update";
          script = ../scripts/config-update.sh;
          description = "Pull runtime desktop config back into the repo.";
          runtimeInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.inetutils
          ];
        };
      };
    in {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
      };

      formatter = config.treefmt.build.wrapper;

      apps = helperApps // {default = helperApps.help;};

      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.bashInteractive
          pkgs.coreutils
          config.treefmt.build.wrapper
          pkgs.findutils
          pkgs.git
          pkgs.gnugrep
          pkgs.gnused
          pkgs.inetutils
          pkgs.just
          pkgs.nix
        ];
      };
    };
  };
}
