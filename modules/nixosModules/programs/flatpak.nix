{
  flake.nixosModules.flatpak = {
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

    # HM-first exception: system-level Flatpak bootstrap is root-managed host plumbing.
    systemd.services.flatpak-bootstrap = {
      description = "Bootstrap Flatpak remote and apps";
      wantedBy = ["multi-user.target"];
      after = [
        "network-online.target"
        "flatpak-system-helper.service"
      ];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "5min";
      };
      script = ''
        FLATPAK="${pkgs.flatpak}/bin/flatpak"
        GREP="${pkgs.gnugrep}/bin/grep"

        if ! "$FLATPAK" --system remotes --columns=name \
            | "$GREP" -Fxq ${lib.escapeShellArg remoteName}; then
          "$FLATPAK" --system remote-add --if-not-exists \
            ${lib.escapeShellArg remoteName} \
            ${lib.escapeShellArg remoteUrl} || {
            echo "flatpak-bootstrap: failed to add remote" >&2
            exit 1
          }
        fi

        while IFS= read -r app; do
          [ -n "$app" ] || continue
          if ! "$FLATPAK" --system list --app --columns=application \
              | "$GREP" -Fxq "$app"; then
            "$FLATPAK" --system install -y \
              ${lib.escapeShellArg remoteName} "$app" \
              || echo "flatpak-bootstrap: warning: failed to install $app" >&2
          fi
        done < ${appsFile}
      '';
    };
  };
}
