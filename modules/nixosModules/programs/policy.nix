{
  flake.nixosModules.policy = {
    lib,
    pkgs,
    config,
    ...
  }: let
    vpnProfileDir = "/home/oj/.config/nixos/configs/users/oj/common/vpn";
    vpnSecretFile = ../../../secrets/vpn.yaml;
    hasVpnSecretFile = builtins.pathExists vpnSecretFile;
  in
    lib.mkMerge [
      {
        # HM-first exception: NetworkManager and firewall are host networking plumbing.
        networking.networkmanager.enable = true;
        networking.networkmanager.plugins = [pkgs.networkmanager-openvpn];
        networking.firewall.enable = true;

        # HM-first exception: VPN profile import is root-owned NetworkManager plumbing.
        systemd.services.vpn-profile-import = {
          description = "Import user-supplied OpenVPN profiles for NetworkManager";
          wantedBy = ["multi-user.target"];
          after = ["NetworkManager.service"];
          wants = ["NetworkManager.service"];
          serviceConfig =
            {
              Type = "oneshot";
              RemainAfterExit = true;
            }
            // lib.optionalAttrs hasVpnSecretFile {
              EnvironmentFile = [
                "-${config.sops.templates."networkmanager-vpn.env".path}"
              ];
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
                "$NMCLI" connection delete id "$profile_id" >/dev/null || true
              fi

              if ! "$NMCLI" --wait 60 connection import type openvpn file "$ovpn" >/dev/null; then
                echo "vpn-profile-import: warning: failed to import $ovpn" >&2
                continue
              fi

              if [ -n "''${VPN_USERNAME:-}" ]; then
                "$NMCLI" connection modify "$profile_id" +vpn.data "username=$VPN_USERNAME" >/dev/null \
                  || echo "vpn-profile-import: warning: failed to set username for $profile_id" >&2
              fi

              if [ -n "''${VPN_PASSWORD:-}" ]; then
                "$NMCLI" connection modify "$profile_id" +vpn.data "password-flags=0" \
                  vpn.secrets "password=$VPN_PASSWORD" >/dev/null \
                  || echo "vpn-profile-import: warning: failed to set password for $profile_id" >&2
              fi
            done < <("$FIND" "$PROFILE_DIR" -maxdepth 1 -type f -name '*.ovpn' -print | "$SORT")
          '';
        };

        warnings = lib.optionals (!hasVpnSecretFile) [
          "SOPS VPN credentials missing at ${toString vpnSecretFile}; imported VPN profiles will prompt for credentials until configured."
        ];

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
      }

      (lib.mkIf hasVpnSecretFile {
        # HM-first exception: credentials for root-owned NetworkManager profiles are system secret plumbing.
        sops.secrets."vpn/username" = {
          sopsFile = vpnSecretFile;
          key = "vpn/username";
        };

        sops.secrets."vpn/password" = {
          sopsFile = vpnSecretFile;
          key = "vpn/password";
        };

        sops.templates."networkmanager-vpn.env".content = ''
          VPN_USERNAME=${config.sops.placeholder."vpn/username"}
          VPN_PASSWORD=${config.sops.placeholder."vpn/password"}
        '';
      })
    ];
}
