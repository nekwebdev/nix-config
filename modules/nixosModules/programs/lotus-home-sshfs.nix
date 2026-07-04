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
  in {
    config = {
      # HM-first exception: this is a root-owned system mount, triggered by systemd.
      environment.systemPackages = [pkgs.sshfs];

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
        requires = [mountUnit];
        after = [mountUnit];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
          ExecStop = "${pkgs.util-linux}/bin/umount -l ${mountPoint}";
        };
      };
    };
  };
}
