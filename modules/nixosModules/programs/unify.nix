{...}: {
  flake.nixosModules.unify = {
    config,
    lib,
    ...
  }: let
    cfg = config.my.unifi.controller;
    containerName = "unifi-os-server";

    requiredTcpPorts = [
      cfg.webPort
      8080
    ];
    optionalTcpPorts = [
      5005
      5671
      6789
      8443
      8444
      8880
      8881
      8882
      9543
      28082
    ];
    requiredUdpPorts = [
      3478
      10003
    ];
    optionalUdpPorts = [
      5514
    ];

    portMappings =
      [
        "${cfg.host}:${toString cfg.webPort}:443"
        "${cfg.host}:8080:8080"
        "${cfg.host}:3478:3478/udp"
        "${cfg.host}:10003:10003/udp"
      ]
      ++ lib.optionals cfg.openOptionalPorts [
        "${cfg.host}:5005:5005"
        "${cfg.host}:5671:5671"
        "${cfg.host}:6789:6789"
        "${cfg.host}:8443:8443"
        "${cfg.host}:8444:8444"
        "${cfg.host}:8880:8880"
        "${cfg.host}:8881:8881"
        "${cfg.host}:8882:8882"
        "${cfg.host}:9543:9543"
        "${cfg.host}:28082:28082"
        "${cfg.host}:5514:5514/udp"
      ];

    dockerOptions =
      [
        "--cgroupns=host"
        "--cap-drop=ALL"
      ]
      ++ map (capability: "--cap-add=${capability}") cfg.capabilities
      ++ [
        "--tmpfs=/run:exec"
        "--tmpfs=/run/lock"
        "--tmpfs=/tmp:exec"
        "--tmpfs=/var/lib/journal"
        "--tmpfs=/var/opt/unifi/tmp:size=64m"
      ]
      ++ cfg.extraOptions;
  in {
    options.my.unifi.controller = with lib; {
      enable = mkEnableOption "UniFi OS Server Docker controller";

      autoStart = mkOption {
        type = types.bool;
        default = false;
        description = "Start the UniFi OS Server container automatically at boot.";
      };

      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "Host address where UniFi OS Server ports are published.";
      };

      systemIp = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = "LAN-reachable IP address or hostname advertised to UniFi devices for inform.";
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/unifi-os-server";
        description = "Persistent state directory mounted at /unifi inside the UniFi OS Server container.";
      };

      image = mkOption {
        type = types.str;
        default = "docker.io/hieutq/unifi-os-server";
        description = "UniFi OS Server container image repository.";
      };

      tag = mkOption {
        type = types.str;
        default = "latest";
        description = "UniFi OS Server container image tag.";
      };

      pull = mkOption {
        type = types.enum [
          "always"
          "missing"
          "never"
          "newer"
        ];
        default = "missing";
        description = "Image pull policy for the UniFi OS Server container.";
      };

      webPort = mkOption {
        type = types.port;
        default = 11443;
        description = "Host TCP port mapped to the UniFi OS Server GUI/API on container port 443.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open UniFi OS Server controller, inform, discovery, STUN, portal, speed test, and syslog ports.";
      };

      openOptionalPorts = mkOption {
        type = types.bool;
        default = true;
        description = "Publish and open optional UniFi OS Server ports for portal redirects, Identity Hub, support files, syslog, and speed tests.";
      };

      uuid = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional fixed UniFi OS Server UUID. Leave null to persist the generated UUID in stateDir.";
      };

      capabilities = mkOption {
        type = types.listOf types.str;
        default = [
          "SYS_ADMIN"
          "NET_ADMIN"
          "NET_RAW"
          "NET_BIND_SERVICE"
          "DAC_OVERRIDE"
          "DAC_READ_SEARCH"
          "FOWNER"
          "CHOWN"
          "SETUID"
          "SETGID"
          "KILL"
          "SYS_CHROOT"
          "SYS_PTRACE"
          "SYS_RESOURCE"
          "AUDIT_WRITE"
          "MKNOD"
        ];
        description = "Linux capabilities granted to the systemd-based UniFi OS Server container.";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Additional environment variables passed to the UniFi OS Server container.";
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional Docker options appended to the UniFi OS Server container run command.";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.virtualisation.docker.enable;
          message = "my.unifi.controller.enable requires virtualisation.docker.enable = true.";
        }
        {
          assertion = cfg.systemIp != "";
          message = "my.unifi.controller.systemIp must be a LAN-reachable address for UniFi inform.";
        }
      ];

      warnings = lib.optionals (cfg.host == "127.0.0.1" || cfg.host == "localhost") [
        "my.unifi.controller.host is loopback; UniFi APs cannot reach inform port 8080 from the LAN."
      ];

      networking.firewall = lib.mkIf cfg.openFirewall {
        allowedTCPPorts = lib.unique (requiredTcpPorts ++ lib.optionals cfg.openOptionalPorts optionalTcpPorts);
        allowedUDPPorts = lib.unique (requiredUdpPorts ++ lib.optionals cfg.openOptionalPorts optionalUdpPorts);
      };

      systemd.tmpfiles.rules = [
        # Container sub-services run as mongodb/postgres/unifi users and need to traverse /unifi.
        "d ${cfg.stateDir} 0755 root root -"
      ];

      virtualisation.oci-containers = {
        backend = "docker";
        containers.${containerName} = {
          image = "${cfg.image}:${cfg.tag}";
          autoStart = cfg.autoStart;
          pull = cfg.pull;
          ports = portMappings;
          environment =
            {
              UOS_SYSTEM_IP = cfg.systemIp;
            }
            // lib.optionalAttrs (cfg.uuid != null) {
              UOS_UUID = cfg.uuid;
            }
            // cfg.environment;
          volumes = [
            "${cfg.stateDir}:/unifi"
            "/sys/fs/cgroup:/sys/fs/cgroup:rw"
          ];
          extraOptions = dockerOptions;
        };
      };
    };
  };
}
