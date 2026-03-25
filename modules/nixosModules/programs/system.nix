{inputs, ...}: {
  flake.nixosModules.system = {lib, ...}: {
    options.my = {
      primaryUser = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Primary interactive user for host-level Home Manager wiring and
          greeter/session paths.
        '';
      };

      users = lib.mkOption {
        default = {};
        description = "Typed user contracts declared by user modules.";
        type = lib.types.attrsOf (
          lib.types.submodule ({name, ...}: {
            options = {
              username = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "System account name.";
              };

              githubUsername = lib.mkOption {
                type = lib.types.str;
                description = "GitHub username used for Git identity and user description.";
              };

              email = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "Primary email address passed through to Home Manager.";
              };

              isAdmin = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether the user should also be a trusted Nix user.";
              };

              primaryGroup = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Primary Unix group for the account.";
              };

              homeDirectory = lib.mkOption {
                type = lib.types.str;
                default = "/home/${name}";
                description = "Home directory for the account.";
              };

              profileModule = lib.mkOption {
                type = lib.types.str;
                default = "${name}Profile";
                description = "Exported Home Manager profile module name.";
              };

              extraGroups = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
                description = "Derived supplementary groups for the account.";
              };
            };
          })
        );
      };
    };

    config = {
      # HM-first exception: global Nix daemon settings are system-level.
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # HM-first exception: package-set overlays are host-level composition plumbing.
      nixpkgs.overlays = lib.mkAfter [inputs.claude-code.overlays.default];

      # HM-first exception: AppImage binfmt registration is system-level kernel/runtime plumbing.
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
  };
}
