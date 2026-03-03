{
  flake.nixosModules.hostLotusFlatpak = {
    lib,
    pkgs,
    ...
  }: let
    flatpakApps = [
      "com.stremio.Stremio"
    ];
    appsFile = pkgs.writeText "lotus-flatpak-apps.txt" (lib.concatStringsSep "\n" flatpakApps + "\n");
    remoteName = "flathub";
    remoteUrl = "https://flathub.org/repo/flathub.flatpakrepo";
  in {
    # HM-first exception: Flatpak daemon and system remotes are root-managed host services.
    services.flatpak.enable = true;

    # HM-first exception: system activation scripts are privileged host bootstrap plumbing.
    system.activationScripts.flatpakBootstrap.text = ''
      FLATPAK_BIN="${pkgs.flatpak}/bin/flatpak"
      GREP_BIN="${pkgs.gnugrep}/bin/grep"
      REMOTE_NAME=${lib.escapeShellArg remoteName}
      REMOTE_URL=${lib.escapeShellArg remoteUrl}

      remote_ready=1

      if ! "$FLATPAK_BIN" --system remotes --columns=name | "$GREP_BIN" -Fxq "$REMOTE_NAME"; then
        if ! "$FLATPAK_BIN" --system remote-add --if-not-exists "$REMOTE_NAME" "$REMOTE_URL"; then
          echo "flatpak-bootstrap: warning: failed to add remote $REMOTE_NAME" >&2
          remote_ready=0
        fi
      fi

      if [ "$remote_ready" -eq 0 ]; then
        echo "flatpak-bootstrap: warning: skipping app install because remote is unavailable" >&2
        exit 0
      fi

      while IFS= read -r app; do
        [ -n "$app" ] || continue

        if ! "$FLATPAK_BIN" --system list --app --columns=application | "$GREP_BIN" -Fxq "$app"; then
          if ! "$FLATPAK_BIN" --system install -y "$REMOTE_NAME" "$app"; then
            echo "flatpak-bootstrap: warning: failed to install $app" >&2
          fi
        fi
      done < ${appsFile}
    '';
  };
}
