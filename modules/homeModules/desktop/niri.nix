{inputs, ...}: {
  flake.homeModules.niri = {
    config,
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";

    niriBinds = {
      "Mod+Space" = {
        hotkey-overlay.title = "Application Launcher";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "spotlight"
          "toggle"
        ];
      };
      "Mod+Ctrl+V" = {
        hotkey-overlay.title = "Clipboard Manager";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "clipboard"
          "toggle"
        ];
      };
      "Mod+M" = {
        hotkey-overlay.title = "Task Manager";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "processlist"
          "toggle"
        ];
      };
      "Mod+N" = {
        hotkey-overlay.title = "Notification Center";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "notifications"
          "toggle"
        ];
      };
      "Mod+Comma" = {
        hotkey-overlay.title = "Settings";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "settings"
          "toggle"
        ];
      };
      "Mod+P" = {
        hotkey-overlay.title = "Notepad";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "notepad"
          "toggle"
        ];
      };
      "Super+Alt+L" = {
        hotkey-overlay.title = "Lock Screen";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "lock"
          "lock"
        ];
      };
      "Mod+X" = {
        hotkey-overlay.title = "Power Menu";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "powermenu"
          "toggle"
        ];
      };
      "Mod+C" = {
        hotkey-overlay.title = "Control Center";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "control-center"
          "toggle"
        ];
      };
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "audio"
          "increment"
          "3"
        ];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "audio"
          "decrement"
          "3"
        ];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "audio"
          "mute"
        ];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "audio"
          "micmute"
        ];
      };
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "brightness"
          "increment"
          "5"
          ""
        ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "brightness"
          "decrement"
          "5"
          ""
        ];
      };
      "Mod+Shift+N" = {
        allow-when-locked = true;
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "night"
          "toggle"
        ];
      };

      "Mod+Return" = {
        hotkey-overlay.title = "Open a Terminal: ghostty";
        action.spawn = "ghostty";
      };

      "Mod+Shift+Slash".action.show-hotkey-overlay = [];

      "Mod+D" = {
        hotkey-overlay.title = "Run an Application: fuzzel";
        action.spawn = "fuzzel";
      };

      "Super+Alt+S" = {
        allow-when-locked = true;
        hotkey-overlay.hidden = true;
        action.spawn-sh = "pkill orca || exec orca";
      };

      "Mod+O" = {
        repeat = false;
        action.toggle-overview = [];
      };

      "Mod+Q" = {
        repeat = false;
        action.close-window = [];
      };

      "Mod+Left".action.focus-column-left = [];
      "Mod+Down".action.focus-window-down = [];
      "Mod+Up".action.focus-window-up = [];
      "Mod+Right".action.focus-column-right = [];
      "Mod+H".action.focus-column-left = [];
      "Mod+J".action.focus-window-down = [];
      "Mod+K".action.focus-window-up = [];
      "Mod+L".action.focus-column-right = [];

      "Mod+Ctrl+Left".action.move-column-left = [];
      "Mod+Ctrl+Down".action.move-window-down = [];
      "Mod+Ctrl+Up".action.move-window-up = [];
      "Mod+Ctrl+Right".action.move-column-right = [];
      "Mod+Ctrl+H".action.move-column-left = [];
      "Mod+Ctrl+J".action.move-window-down = [];
      "Mod+Ctrl+K".action.move-window-up = [];
      "Mod+Ctrl+L".action.move-column-right = [];

      "Mod+Home".action.focus-column-first = [];
      "Mod+End".action.focus-column-last = [];
      "Mod+Ctrl+Home".action.move-column-to-first = [];
      "Mod+Ctrl+End".action.move-column-to-last = [];

      "Mod+Shift+Left".action.focus-monitor-left = [];
      "Mod+Shift+Down".action.focus-monitor-down = [];
      "Mod+Shift+Up".action.focus-monitor-up = [];
      "Mod+Shift+Right".action.focus-monitor-right = [];
      "Mod+Shift+H".action.focus-monitor-left = [];
      "Mod+Shift+J".action.focus-monitor-down = [];
      "Mod+Shift+K".action.focus-monitor-up = [];
      "Mod+Shift+L".action.focus-monitor-right = [];

      "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [];
      "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [];
      "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [];
      "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [];
      "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [];
      "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [];
      "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [];
      "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [];

      "Mod+Page_Down".action.focus-workspace-down = [];
      "Mod+Page_Up".action.focus-workspace-up = [];
      "Mod+U".action.focus-workspace-down = [];
      "Mod+I".action.focus-workspace-up = [];
      "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [];
      "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [];
      "Mod+Ctrl+U".action.move-column-to-workspace-down = [];
      "Mod+Ctrl+I".action.move-column-to-workspace-up = [];

      "Mod+Shift+Page_Down".action.move-workspace-down = [];
      "Mod+Shift+Page_Up".action.move-workspace-up = [];
      "Mod+Shift+U".action.move-workspace-down = [];
      "Mod+Shift+I".action.move-workspace-up = [];

      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action.focus-workspace-down = [];
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action.focus-workspace-up = [];
      };
      "Mod+Ctrl+WheelScrollDown" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-down = [];
      };
      "Mod+Ctrl+WheelScrollUp" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-up = [];
      };

      "Mod+WheelScrollRight".action.focus-column-right = [];
      "Mod+WheelScrollLeft".action.focus-column-left = [];
      "Mod+Ctrl+WheelScrollRight".action.move-column-right = [];
      "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [];

      "Mod+Shift+WheelScrollDown".action.focus-column-right = [];
      "Mod+Shift+WheelScrollUp".action.focus-column-left = [];
      "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [];
      "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [];

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      "Mod+BracketLeft".action.consume-or-expel-window-left = [];
      "Mod+BracketRight".action.consume-or-expel-window-right = [];
      "Mod+Period".action.expel-window-from-column = [];

      "Mod+R".action.switch-preset-column-width = [];
      "Mod+Shift+R".action.switch-preset-window-height = [];
      "Mod+Ctrl+R".action.reset-window-height = [];
      "Mod+F".action.maximize-column = [];
      "Mod+Shift+F".action.fullscreen-window = [];
      "Mod+Ctrl+F".action.expand-column-to-available-width = [];
      "Mod+Ctrl+C".action.center-visible-columns = [];

      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      "Mod+V".action.toggle-window-floating = [];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];
      "Mod+W".action.toggle-column-tabbed-display = [];

      "Mod+Shift+P".action.screenshot = [];
      "Mod+Ctrl+P".action.screenshot-screen = [];
      "Mod+Ctrl+Shift+P".action.screenshot-window = [];

      "Mod+Escape" = {
        allow-inhibiting = false;
        action.toggle-keyboard-shortcuts-inhibit = [];
      };

      "Mod+Shift+E".action.quit = [];
      "Ctrl+Alt+Delete".action.quit = [];
      "Mod+Alt+P".action.power-off-monitors = [];
    };
  in {
    imports = [inputs.dms.homeModules.niri];

    config = lib.mkIf isLotus {
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

      programs.niri.settings = {
        binds = niriBinds;

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
