{...}: {
  flake.homeModules.vscode = {
    config,
    lib,
    pkgs,
    ...
  }: let
    homeDirectory = config.home.homeDirectory;
  in {
    config = {
      programs.vscode = {
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

      home.activation.vscodeArgvPasswordStore = lib.hm.dag.entryAfter ["writeBoundary"] ''
        argv_file="${homeDirectory}/.vscode-oss/argv.json"
        password_store_line='"password-store":"gnome-libsecret"'

        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$argv_file")"

        if [ ! -f "$argv_file" ]; then
          cat > "$argv_file" <<'EOF'
        {
          "password-store":"gnome-libsecret"
        }
        EOF
        elif ! ${pkgs.gnugrep}/bin/grep -Fq "$password_store_line" "$argv_file"; then
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
        fi
      '';
    };
  };
}
