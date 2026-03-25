{
  flake.nixosModules.policy = {
    lib,
    config,
    pkgs,
    ...
  }: let
    primaryUserName = lib.attrByPath ["my" "primaryUser"] null config;
    primaryUser =
      if primaryUserName == null
      then null
      else lib.attrByPath ["my" "users" primaryUserName] null config;
    vpnProfileDir =
      if primaryUser == null
      then null
      else "${primaryUser.homeDirectory}/.config/ovpn";
  in {
    # HM-first exception: NetworkManager and firewall are host networking plumbing.
    networking.networkmanager.enable = true;
    networking.networkmanager.plugins = [pkgs.networkmanager-openvpn];
    networking.firewall.enable = true;

    # HM-first exception: VPN profile import is root-owned NetworkManager plumbing.
    systemd.services.vpn-profile-import = lib.mkIf (vpnProfileDir != null) {
      description = "One-time import of OpenVPN profiles from the primary user's ~/.config/ovpn";
      wantedBy = ["multi-user.target"];
      after = ["NetworkManager.service"];
      wants = ["NetworkManager.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        PROFILE_DIR=${lib.escapeShellArg vpnProfileDir}
        NMCLI="${pkgs.networkmanager}/bin/nmcli"
        BASENAME="${pkgs.coreutils}/bin/basename"
        FIND="${pkgs.findutils}/bin/find"
        GREP="${pkgs.gnugrep}/bin/grep"
        SORT="${pkgs.coreutils}/bin/sort"

        if [ ! -d "$PROFILE_DIR" ]; then
          echo "vpn-profile-import: profile directory not found: $PROFILE_DIR" >&2
          exit 0
        fi

        while IFS= read -r ovpn; do
          [ -n "$ovpn" ] || continue
          profile_id="$("$BASENAME" "$ovpn" .ovpn)"

          if "$NMCLI" --terse --fields NAME,TYPE connection show \
              | "$GREP" -Fxq "''${profile_id}:vpn"; then
            continue
          fi

          if ! "$NMCLI" --wait 60 connection import type openvpn file "$ovpn" >/dev/null; then
            echo "vpn-profile-import: warning: failed to import $ovpn" >&2
          fi
        done < <("$FIND" "$PROFILE_DIR" -maxdepth 1 -type f -name '*.ovpn' -print | "$SORT")
      '';
    };

    # HM-first exception: sudo policy is a privileged system concern.
    security.sudo.wheelNeedsPassword = lib.mkForce true;

    # HM-first exception: login-shell handoff is host-wide shell policy for system bash.
    programs.bash.interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';

    # HM-first exception: dynamic linker compatibility for third-party binaries is system runtime plumbing.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libcap
        xz
        openssl
        zlib
      ];
    };
  };
}
