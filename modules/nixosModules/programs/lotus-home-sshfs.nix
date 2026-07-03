{
  flake.nixosModules.lotusHomeSshfs = {
    lib,
    pkgs,
    ...
  }: let
    mountPoint = "/home/oj/Mounts/lotus-home";
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

      systemd.automounts = [
        {
          description = "Automount Lotus home over SSHFS";
          where = mountPoint;
          wantedBy = ["multi-user.target"];
          automountConfig.TimeoutIdleSec = "5min";
        }
      ];

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
    };
  };
}
