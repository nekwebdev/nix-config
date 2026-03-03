{self, ...}: {
  flake.homeModules.userOj = {
    config,
    lib,
    osConfig ? {},
    pkgs,
    wrappedPrograms,
    sopsUserSshKeyPath ? null,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
    homeDirectory = config.home.homeDirectory;
  in {
    imports =
      [
        self.homeModules.fishEnv
        self.homeModules.aliasRegistry
        self.homeModules.aliasesCommon
      ]
      ++ lib.optionals isLotus [
        self.homeModules.bat
        self.homeModules.brave
        self.homeModules.eza
        self.homeModules.fastfetch
        self.homeModules.fzf
        self.homeModules.niri
        self.homeModules.dms
        self.homeModules.starship
        self.homeModules.tlrc
        self.homeModules.zoxide
      ];

    assertions = [
      {
        assertion = sopsUserSshKeyPath != null;
        message = "homeModules.userOj requires `home-manager.extraSpecialArgs.sopsUserSshKeyPath` to match the SOPS user key.";
      }
    ];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;

    # HM-first: user-scoped packages and session variables from legacy lotus config.
    home.packages = lib.mkIf isLotus [
      pkgs.discord
      pkgs.fira-code
      pkgs.fira-code-symbols
      pkgs.nautilus
      pkgs.nerd-fonts.fira-code
      pkgs.openvpn
      pkgs.protonup-qt
      pkgs.codex
    ];

    home.sessionVariables = lib.mkIf isLotus {
      CODEX_HOME = "${config.home.homeDirectory}/.config/codex";
      TERMINAL = "ghostty";
    };

    gtk = lib.mkIf isLotus {
      enable = true;
      theme = {
        name = "adw-gtk3";
        package = pkgs.adw-gtk3;
      };
    };

    xdg.configFile."gtk-4.0/gtk.css".source = lib.mkIf isLotus (
      pkgs.writeText "gtk-4.0-gtk.css" ''
        @import url("dank-colors.css");
      ''
    );

    home.pointerCursor = lib.mkIf isLotus {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 14;
      x11 = {
        enable = true;
        defaultCursor = "Adwaita";
      };
    };

    programs.git = {
      enable = true;
      package = wrappedPrograms.git;
      settings = {
        user = {
          name = "nekwebdev";
          email = "nekwebdev@users.noreply.github.com";
          signingkey = sopsUserSshKeyPath;
        };
        init.defaultBranch = "main";
        gpg.format = "ssh";
        commit.gpgSign = true;
        core.pager = "diff-so-fancy | less --tabs=4 -RFX";
        interactive.diffFilter = "diff-so-fancy --patch";
      };
    };

    programs.mangohud = lib.mkIf isLotus {
      enable = true;
      settings = {
        control = "mangohud";
        fsr_steam_sharpness = 5;
        nis_steam_sharpness = 10;
        legacy_layout = 0;
        horizontal = true;
        position = "top-center";
        gpu_stats = true;
        cpu_stats = true;
        cpu_power = true;
        gpu_power = true;
        ram = true;
        fps = true;
        frametime = 0;
        hud_no_margin = true;
        table_columns = 14;
        frame_timing = 1;
      };
    };

    programs.zed-editor = lib.mkIf isLotus {
      enable = true;
      extraPackages = with pkgs; [
        nil
        nixd
      ];
    };

    programs.vscode = lib.mkIf isLotus {
      enable = true;
      package = pkgs.vscodium;

      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          eamodio.gitlens
          tamasfe.even-better-toml
          github.vscode-pull-request-github
        ];

        userSettings = {
          "editor.fontFamily" = "'FiraCode Nerd Font', 'Fira Code', monospace";
          "terminal.integrated.fontFamily" = "'FiraCode Nerd Font', 'Fira Code', monospace";
          "editor.fontSize" = 16;
          "editor.tabSize" = 2;
          "editor.formatOnSave" = false;
          "editor.fontLigatures" = true;
          "editor.lineHeight" = 20;
          "editor.minimap.enabled" = true;
          "chat.fontSize" = 16;
          "chat.editor.fontSize" = 15;
          "breadcrumbs.enabled" = true;
          "workbench.fontAliasing" = "antialiased";
          "workbench.sideBar.location" = "right";
          "workbench.colorTheme" = "Dynamic Base16 DankShell (Dark)";
          "telemetry.telemetryLevel" = "off";
          "telemetry.enableCrashReporter" = false;
          "files.exclude" = {
            "**/node_modules/**" = true;
          };
          "files.trimTrailingWhitespace" = true;
        };
      };
    };

    home.activation.vscodeArgvPasswordStore = lib.mkIf isLotus (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        argv_file="${homeDirectory}/.vscode-oss/argv.json"
        password_store_line='"password-store":"gnome-libsecret"'

        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$argv_file")"

        if [ ! -f "$argv_file" ]; then
          cat > "$argv_file" <<'EOF'
        {
          "password-store":"gnome-libsecret"
        }
        EOF
          exit 0
        fi

        if ${pkgs.gnugrep}/bin/grep -Fq "$password_store_line" "$argv_file"; then
          exit 0
        fi

        close_line="$(${pkgs.gnugrep}/bin/grep -n '^[[:space:]]*}[[:space:]]*$' "$argv_file" | ${pkgs.coreutils}/bin/tail -n1 | ${pkgs.coreutils}/bin/cut -d: -f1)"
        if [ -n "$close_line" ] && [ "$close_line" -gt 1 ]; then
          prev_line="$((close_line - 1))"
          if ${pkgs.gnused}/bin/sed -n "''${prev_line}p" "$argv_file" | ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*"[^"]+":.*,[[:space:]]*$'; then
            :
          else
            ${pkgs.gnused}/bin/sed -i "''${prev_line}s/[[:space:]]*$/,/" "$argv_file"
          fi
        fi

        ${pkgs.gnused}/bin/sed -i '/^[[:space:]]*}[[:space:]]*$/i\  "password-store":"gnome-libsecret"' "$argv_file"
      ''
    );

    programs.ghostty = lib.mkIf isLotus {
      enable = true;
      settings = {
        theme = "dankcolors";
        font-family = "FiraCode Nerd Font";
        font-size = 12;

        window-decoration = false;
        window-padding-x = 12;
        window-padding-y = 12;
        background-opacity = 0.9;
        background-blur = true;

        cursor-style = "block";
        cursor-style-blink = true;

        scrollback-limit = 3023;

        mouse-hide-while-typing = true;
        copy-on-select = true;
        confirm-close-surface = false;

        app-notifications = "no-clipboard-copy,no-config-reload";

        keybind = [
          "ctrl+shift+n=new_window"
          "ctrl+t=new_tab"
          "ctrl+plus=increase_font_size:1"
          "ctrl+minus=decrease_font_size:1"
          "ctrl+zero=reset_font_size"
          "shift+enter=text:\\n"
        ];

        unfocused-split-opacity = 0.7;
        unfocused-split-fill = "#44464f";

        gtk-titlebar = false;

        shell-integration = "detect";
        shell-integration-features = "cursor,sudo,title,no-cursor";
      };
    };
  };
}
