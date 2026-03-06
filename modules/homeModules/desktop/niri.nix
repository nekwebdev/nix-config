{inputs, ...}: {
  flake.homeModules.niri = {
    config,
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    runtimeConfigHelper = "${repoRoot}/scripts/runtime-config-helper.sh";
    runtimeUser = config.home.username or "";
    runtimeHost = osConfig.networking.hostName or "";
    niriIncludeSources =
      [
        "${repoRoot}/configs/common/niri"
        "${repoRoot}/configs/users/${runtimeUser}/common/niri"
      ]
      ++ lib.optionals (runtimeHost != "") ["${repoRoot}/configs/users/${runtimeUser}/hosts/${runtimeHost}/niri"];
    niriIncludeDirs = lib.filter builtins.pathExists niriIncludeSources;
    niriIncludeNames = lib.sort builtins.lessThan (
      lib.unique (
        lib.concatMap (dir:
          map
          (name: lib.removeSuffix ".kdl" name)
          (lib.attrNames (lib.filterAttrs (_: fileType: fileType == "regular") (builtins.readDir dir))))
        niriIncludeDirs
      )
    );
  in {
    imports = [inputs.dms.homeModules.niri];

    config = {
      home.activation.niriRuntimeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/env \
          RUNTIME_CONFIG_USER=${lib.escapeShellArg runtimeUser} \
          RUNTIME_CONFIG_HOST=${lib.escapeShellArg runtimeHost} \
          ${pkgs.bash}/bin/bash ${runtimeConfigHelper} seed niri
      '';

      home.packages =
        (lib.optionals (pkgs ? niri) [pkgs.niri])
        ++ [
          pkgs.xwayland-satellite
          pkgs.alacritty
          pkgs.grim
          pkgs.slurp
          pkgs.wl-clipboard
        ]
        ++ lib.optionals (pkgs ? niri-tools) [pkgs.niri-tools];

      home.sessionVariables = {
        NIRI_CONFIG = "${config.xdg.configHome}/niri/config.kdl";
      };

      programs.dank-material-shell.niri = {
        enableSpawn = true;
        enableKeybinds = false;
        includes = {
          enable = true;
          override = true;
          originalFileName = "hm";
          filesToInclude = niriIncludeNames;
        };
      };

      programs.niri.settings = {
        # binds = niriBinds;

        environment = {
          XDG_CURRENT_DESKTOP = "niri";
          QT_QPA_PLATFORM = "wayland";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORMTHEME = "gtk3";
          QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
        };

        spawn-at-startup = [
          {
            argv = [
              "bash"
              "-c"
              "wl-paste --watch cliphist store &"
            ];
          }
        ];

        config-notification.disable-failed = true;

        input = {
          keyboard = {
            repeat-delay = 250;
            repeat-rate = 35;
          };

          focus-follows-mouse.enable = true;
          focus-follows-mouse.max-scroll-amount = "0%";
        };

        gestures.hot-corners.enable = false;

        layout = {
          background-color = "transparent";
          center-focused-column = "never";
          always-center-single-column = true;
          preset-column-widths = [
            {proportion = 1. / 3.;}
            {proportion = 1. / 2.;}
            {proportion = 2. / 3.;}
          ];
          default-column-width = {
            proportion = 1. / 2.;
          };
        };

        overview.workspace-shadow.enable = false;

        hotkey-overlay.skip-at-startup = true;

        prefer-no-csd = true;

        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

        animations = {
          workspace-switch.kind.spring = {
            damping-ratio = 0.80;
            stiffness = 523;
            epsilon = 0.0001;
          };

          window-open.kind.easing = {
            duration-ms = 150;
            curve = "ease-out-expo";
          };

          window-close.kind.easing = {
            duration-ms = 150;
            curve = "ease-out-quad";
          };

          horizontal-view-movement.kind.spring = {
            damping-ratio = 0.85;
            stiffness = 423;
            epsilon = 0.0001;
          };

          window-movement.kind.spring = {
            damping-ratio = 0.75;
            stiffness = 323;
            epsilon = 0.0001;
          };

          window-resize.kind.spring = {
            damping-ratio = 0.85;
            stiffness = 423;
            epsilon = 0.0001;
          };

          config-notification-open-close.kind.spring = {
            damping-ratio = 0.65;
            stiffness = 923;
            epsilon = 0.001;
          };

          screenshot-ui-open.kind.easing = {
            duration-ms = 200;
            curve = "ease-out-quad";
          };

          overview-open-close.kind.spring = {
            damping-ratio = 0.85;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };

        layer-rules = [
          {
            matches = [
              {namespace = "^quickshell$";}
            ];
            place-within-backdrop = true;
          }
        ];

        window-rules = [
          {
            matches = [
              {app-id = "^org\\.wezfurlong\\.wezterm$";}
            ];
            default-column-width = {};
          }
          {
            matches = [
              {app-id = "^org\\.gnome\\.";}
            ];
            draw-border-with-background = false;
          }
          {
            matches = [
              {app-id = "^gnome-control-center$";}
              {app-id = "^pavucontrol$";}
              {app-id = "^nm-connection-editor$";}
            ];
            default-column-width = {
              proportion = 0.5;
            };
            open-floating = false;
          }
          {
            matches = [
              {app-id = "org.quickshell$";}
              {app-id = "^gnome-calculator$";}
              {app-id = "^galculator$";}
              {app-id = "^blueman-manager$";}
              {app-id = "^org\\.gnome\\.Nautilus$";}
              {app-id = "^xdg-desktop-portal$";}
              {
                app-id = "brave$";
                title = "^Picture-in-Picture$";
              }
              {app-id = "zoom";}
            ];
            open-floating = true;
          }
          {
            matches = [
              {app-id = "^org\\.wezfurlong\\.wezterm$";}
              {app-id = "Alacritty";}
              {app-id = "zen";}
              {app-id = "com.mitchellh.ghostty";}
              {app-id = "kitty";}
            ];
            draw-border-with-background = false;
          }
          {
            matches = [
              {app-id = "^steam_app_3564740$";}
            ];
            open-fullscreen = true;
          }
          {
            geometry-corner-radius = {
              top-left = 6.0;
              top-right = 6.0;
              bottom-left = 6.0;
              bottom-right = 6.0;
            };
            clip-to-geometry = true;
            draw-border-with-background = false;
          }
        ];

        outputs."*" = {
          scale = 1.0;
        };

        debug = {
          honor-xdg-activation-with-invalid-serial = [];
        };
      };
    };
  };
}
