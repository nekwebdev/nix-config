{self, ...}: {
  flake.homeModules.ojBase = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.homeModules.base
      self.homeModules.environment
      self.homeModules.fish
      self.homeModules.aliasRegistry
      self.homeModules.aliasesCommon
      self.homeModules.git
      self.homeModules.bat
      self.homeModules.brave
      self.homeModules.eza
      self.homeModules.fastfetch
      self.homeModules.fzf
      self.homeModules.ghostty
      self.homeModules.herdr
      self.homeModules.mangohud
      self.homeModules.nixMonitor
      self.homeModules.nixvim
      self.homeModules.obsidian
      self.homeModules.starship
      self.homeModules.tmux
      self.homeModules.tlrc
      self.homeModules.vscode
      self.homeModules.zedEditor
      self.homeModules.zenBrowser
      self.homeModules.zoxide
      self.homeModules.niri
      self.homeModules.dms
    ];

    options.my.home.flatpak.apps = lib.mkOption {
      default = [];
      description = "Flatpak app IDs requested by this user profile.";
      type = lib.types.listOf lib.types.str;
    };

    config = {
      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3";
          package = pkgs.adw-gtk3;
        };
        gtk4.theme = config.gtk.theme;
        gtk4.extraCss = ''
          @import url("dank-colors.css");
        '';
      };

      home.pointerCursor = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 14;
        x11 = {
          enable = true;
          defaultCursor = "Adwaita";
        };
      };

      # HM-first: user-scoped packages shared by oj profiles.
      home.packages = [
        pkgs.bun
        pkgs.discord
        pkgs.fira-code
        pkgs.fira-code-symbols
        pkgs.img2pdf
        pkgs.nautilus
        pkgs.nerd-fonts.fira-code
        pkgs.nodejs
        pkgs.pnpm
        pkgs.protonup-qt
        pkgs.simple-scan
        pkgs.faugus-launcher
        pkgs.mpv
      ];

      home.file.".local/bin/ds640-scan-pdf" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          scanimage="${pkgs.sane-backends}/bin/scanimage"
          img2pdf="${pkgs.img2pdf}/bin/img2pdf"
          awk="${pkgs.gawk}/bin/awk"

          if (($# > 1)); then
            echo "Usage: ds640-scan-pdf [output.pdf]" >&2
            exit 2
          fi

          if (($# == 1)) && { [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; }; then
            echo "Usage: ds640-scan-pdf [output.pdf]"
            exit 0
          fi

          if (($# == 1)); then
            output="$1"
          else
            output="$HOME/Documents/ds640-$(${pkgs.coreutils}/bin/date +%F-%H%M%S).pdf"
          fi

          if [[ -e "$output" ]]; then
            echo "Output already exists: $output" >&2
            exit 1
          fi

          # shellcheck disable=SC2016 # AWK program intentionally uses literal field references.
          device="$("$scanimage" --formatted-device-list='%d|%v|%m%n' | "$awk" -F'|' '$2 == "Brother" && $3 == "DS-640" && !found { print $1; found = 1 }')"
          if [[ -z "$device" ]]; then
            echo "Brother DS-640 not found. Reconnect it, then run scanimage -L." >&2
            exit 1
          fi

          tmp="$(${pkgs.coreutils}/bin/mktemp -d)"
          cleanup() {
            ${pkgs.coreutils}/bin/rm -rf -- "$tmp"
          }
          trap cleanup EXIT

          echo "Using scanner: $device"
          echo "Mode: 24bit Color[Fast], resolution: 300 dpi"
          echo "Reopening scanner for each page so brscan5 detects newly loaded paper."

          pages=()
          page_number=1
          while true; do
            if (( ''${#pages[@]} == 0 )); then
              prompt="Load page $page_number, then press Enter to scan (q to quit): "
            else
              prompt="Load page $page_number, then press Enter to scan (q to create PDF): "
            fi

            if ! IFS= read -r -p "$prompt" action; then
              action=q
              echo
            fi

            case "$action" in
              q | Q)
                break
                ;;
              "")
                ;;
              *)
                echo "Enter scans; q finishes." >&2
                continue
                ;;
            esac

            printf -v page_file '%s/page-%03d.png' "$tmp" "$page_number"
            scan_error="$tmp/scan-error.log"

            # Give the sheet sensor time to settle, then open a fresh SANE session.
            ${pkgs.coreutils}/bin/sleep 1
            if "$scanimage" \
              --device-name "$device" \
              --resolution 300 \
              --mode '24bit Color[Fast]' \
              --format png \
              --output-file="$page_file" \
              2>"$scan_error"; then
              pages+=("$page_file")
              echo "Scanned page $page_number."
              ((page_number += 1))
            else
              ${pkgs.coreutils}/bin/cat "$scan_error" >&2
              ${pkgs.coreutils}/bin/rm -f -- "$page_file"
              echo "Page $page_number failed. Check paper, then press Enter to retry or q to finish." >&2
            fi
          done

          if (( ''${#pages[@]} == 0 )); then
            echo "No pages were scanned." >&2
            exit 1
          fi

          ${pkgs.coreutils}/bin/mkdir -p -- "$(${pkgs.coreutils}/bin/dirname -- "$output")"
          "$img2pdf" "''${pages[@]}" --output "$output"
          echo "Created $output"
        '';
      };

      my.home.flatpak.apps = [
        "com.stremio.Stremio"
      ];

      home.stateVersion = "25.11";
      programs.home-manager.enable = true;
    };
  };
}
