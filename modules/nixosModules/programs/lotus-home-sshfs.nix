{
  flake.nixosModules.lotusHomeSshfs = {
    lib,
    pkgs,
    ...
  }: let
    mountPoint = "/home/oj/Mounts/lotus-home";
    mountUnit = "home-oj-Mounts-lotus\\x2dhome.mount";
    mountOptions = [
      "allow_other"
      "default_permissions"
      "uid=1000"
      "gid=993"
      "BatchMode=yes"
      "reconnect"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
      "ConnectTimeout=10"
      "ConnectionAttempts=1"
      "StrictHostKeyChecking=accept-new"
      "UserKnownHostsFile=/home/oj/.ssh/known_hosts"
      "idmap=user"
    ];
    lotusHomeStart = pkgs.writeShellScript "lotus-home-start" ''
      set -euo pipefail

      if ${pkgs.util-linux}/bin/mountpoint -q '${mountPoint}'; then
        echo "lotus-home: already mounted at ${mountPoint}"
        exit 0
      fi

      echo "lotus-home: checking Tailscale SSH auth for oj@lotus"
      echo "lotus-home: if a Tailscale auth URL appears, open it and approve; this start waits up to 5 minutes"
      ${pkgs.util-linux}/bin/runuser -u oj -- ${pkgs.coreutils}/bin/env \
        HOME=/home/oj \
        USER=oj \
        LOGNAME=oj \
        XDG_CONFIG_HOME=/home/oj/.config \
        PATH="${lib.makeBinPath [pkgs.openssh pkgs.tailscale]}" \
        ${pkgs.tailscale}/bin/tailscale ssh oj@lotus true

      echo "lotus-home: Tailscale SSH auth OK; starting ${mountUnit}"
      ${pkgs.systemd}/bin/systemctl start '${mountUnit}'
      ${pkgs.util-linux}/bin/mountpoint -q '${mountPoint}'
      echo "lotus-home: mounted ${mountPoint}"
    '';
    lotusHomeStop = pkgs.writeShellScript "lotus-home-stop" ''
      set -euo pipefail

      ${pkgs.systemd}/bin/systemctl stop '${mountUnit}' 2>/dev/null || true
      ${pkgs.util-linux}/bin/umount -l '${mountPoint}' 2>/dev/null || true
    '';
    lotusHomeMount = pkgs.writeShellScriptBin "lotus-home-mount" ''
      set -euo pipefail

      unit=lotus-home.service
      mount_unit='${mountUnit}'
      tail_pid=""

      cleanup() {
        if [ -n "$tail_pid" ]; then
          kill "$tail_pid" 2>/dev/null || true
          wait "$tail_pid" 2>/dev/null || true
        fi
      }

      /run/wrappers/bin/sudo -v

      echo "lotus-home: starting $unit; streaming logs until start finishes"
      /run/wrappers/bin/sudo ${pkgs.systemd}/bin/journalctl --no-pager -n 0 -f -u "$unit" -u "$mount_unit" &
      tail_pid=$!
      trap cleanup EXIT INT TERM
      ${pkgs.coreutils}/bin/sleep 0.2

      /run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start "$unit"
      ${pkgs.coreutils}/bin/sleep 0.2
      echo "lotus-home: start finished"
    '';
  in {
    config = {
      # HM-first exception: this is a root-owned system mount, triggered by systemd.
      environment.systemPackages = [
        pkgs.sshfs
        lotusHomeMount
      ];

      programs.fuse = {
        enable = true;
        userAllowOther = true;
      };

      systemd.tmpfiles.rules = [
        "d /home/oj/Mounts 0755 oj oj -"
        "d ${mountPoint} 0755 oj oj -"
      ];

      # SSHFS/FUSE does not support systemd's remount/reload path. When
      # switch-to-configuration queues this mount for reload, stop it first so
      # activation can start it cleanly instead of failing the switch.
      system.activationScripts.lotusHomeSshfsAvoidFuseRemount = ''
        reloadList=/run/nixos/reload-list

        if [ -e "$reloadList" ] && ${pkgs.gnugrep}/bin/grep -Fqx '${mountUnit}' "$reloadList"; then
          ${pkgs.util-linux}/bin/umount -l '${mountPoint}' 2>/dev/null || true
          ${pkgs.coreutils}/bin/timeout 5s ${pkgs.systemd}/bin/systemctl stop '${mountUnit}' 2>/dev/null || true
          ${pkgs.systemd}/bin/systemctl reset-failed '${mountUnit}' 2>/dev/null || true
        fi
      '';

      systemd.mounts = [
        {
          description = "Mount Lotus home over SSHFS";
          # Manual-only: started by lotus-home.service/lotus-home-mount, not boot.
          wantedBy = [];
          what = "oj@100.112.114.97:/home/oj";
          where = mountPoint;
          type = "fuse.sshfs";
          options = lib.concatStringsSep "," mountOptions;
          wants = [
            "network-online.target"
            "tailscaled.service"
          ];
          after = [
            "network-online.target"
            "tailscaled.service"
          ];
          mountConfig.TimeoutSec = "30s";
        }
      ];

      systemd.services.lotus-home = {
        description = "Manual Lotus home SSHFS mount";
        # Manual-only: do not start at boot, and do not restart during nixos-rebuild switch.
        wantedBy = [];
        restartIfChanged = false;
        stopIfChanged = false;
        wants = [
          "network-online.target"
          "tailscaled.service"
        ];
        after = [
          "network-online.target"
          "tailscaled.service"
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "5min";
          StandardOutput = "journal+console";
          StandardError = "journal+console";
          ExecStart = "${lotusHomeStart}";
          ExecStop = "${lotusHomeStop}";
        };
      };
    };
  };
}
