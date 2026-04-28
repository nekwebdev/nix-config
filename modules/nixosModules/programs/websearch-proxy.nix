{...}: {
  flake.nixosModules.websearchProxy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.my.assistants.webSearch.proxy;
    searxngContainerName = "websearch-searxng";
    percentType = lib.types.addCheck lib.types.int (value: value >= 0 && value <= 100);
    checkBaseUrl = lib.removeSuffix "/" cfg.baseUrl;
    webSearchSecretFile = ../../../secrets/hermes-websearch.env.sops;
    webSearchSecretExists = builtins.pathExists webSearchSecretFile;
    hermesEnabled = lib.attrByPath ["services" "hermes-agent" "enable"] false config;
  in {
    options.my.assistants.webSearch.proxy = with lib; {
      enable = mkEnableOption "local Firecrawl-compatible websearch proxy runtime";

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Bind host for local websearch proxy listener.";
      };

      port = mkOption {
        type = types.port;
        default = 8082;
        description = "Host TCP port exposed for local websearch proxy.";
      };

      baseUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:8082";
        description = "Base URL Hermes uses for Firecrawl-compatible web backend.";
      };

      image = mkOption {
        type = types.str;
        default = "ghcr.io/nekwebdev/websearch-proxy";
        description = "Websearch proxy container image repository.";
      };

      tag = mkOption {
        type = types.str;
        default = "latest";
        description = "Websearch proxy container image tag.";
      };

      networkName = mkOption {
        type = types.str;
        default = "websearch-proxy-net";
        description = "Docker network name shared by proxy and embedded SearXNG.";
      };

      searxng = {
        image = mkOption {
          type = types.str;
          default = "ghcr.io/nekwebdev/websearch-searxng";
          description = "SearXNG sidecar container image repository.";
        };

        tag = mkOption {
          type = types.str;
          default = "2026.4.24-a7ac696b4";
          description = "SearXNG sidecar container image tag.";
        };
      };

      logLevel = mkOption {
        type = types.str;
        default = "INFO";
        description = "Runtime log level for proxy.";
      };

      routeDecisionLogging = mkOption {
        type = types.bool;
        default = true;
        description = "Enable route decision logging in proxy runtime.";
      };

      tavily = {
        dailySoftCapCalls = mkOption {
          type = types.int;
          default = 8;
          description = "Daily soft cap for Tavily calls.";
        };

        monthlyCapCalls = mkOption {
          type = types.int;
          default = 150;
          description = "Monthly hard cap for Tavily calls.";
        };

        reservePercentCritical = mkOption {
          type = percentType;
          default = 25;
          description = "Percent of monthly Tavily budget reserved for critical routes.";
        };
      };

      healthcheck = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable periodic systemd HTTP health checks for websearch proxy.";
        };

        interval = mkOption {
          type = types.str;
          default = "2m";
          description = "systemd timer interval for websearch proxy health checks.";
        };
      };
    };

    config = lib.mkIf cfg.enable {
      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          ${searxngContainerName} = {
            image = "${cfg.searxng.image}:${cfg.searxng.tag}";
            autoStart = true;
            extraOptions = [
              "--network=${cfg.networkName}"
              "--health-cmd=wget -qO- http://127.0.0.1:8080/ >/dev/null"
              "--health-interval=30s"
              "--health-timeout=5s"
              "--health-retries=5"
              "--health-start-period=20s"
            ];
          };

          websearch-proxy = {
            image = "${cfg.image}:${cfg.tag}";
            autoStart = true;
            ports = [
              "${cfg.host}:${toString cfg.port}:8080"
            ];
            environment = {
              LOG_LEVEL = cfg.logLevel;
              ROUTE_DECISION_LOGGING = lib.boolToString cfg.routeDecisionLogging;
              TAVILY_DAILY_SOFT_CAP_CALLS = toString cfg.tavily.dailySoftCapCalls;
              TAVILY_MONTHLY_CAP_CALLS = toString cfg.tavily.monthlyCapCalls;
              TAVILY_RESERVE_PERCENT_CRITICAL = toString cfg.tavily.reservePercentCritical;
              SEARXNG_BASE_URL = "http://${searxngContainerName}:8080";
            };
            environmentFiles = lib.optionals webSearchSecretExists [
              config.sops.secrets.hermesWebSearchEnv.path
            ];
            extraOptions = [
              "--network=${cfg.networkName}"
              ''--health-cmd=python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=2)"''
              "--health-interval=30s"
              "--health-timeout=5s"
              "--health-retries=5"
              "--health-start-period=20s"
            ];
          };
        };
      };

      assertions = [
        {
          assertion = config.virtualisation.docker.enable;
          message = "my.assistants.webSearch.proxy.enable requires virtualisation.docker.enable = true.";
        }
      ];

      systemd.services =
        {
          websearch-proxy-network = {
            description = "Create Docker network for websearch proxy stack";
            wantedBy = ["multi-user.target"];
            after = ["docker.service"];
            wants = ["docker.service"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              ${pkgs.docker}/bin/docker network inspect ${lib.escapeShellArg cfg.networkName} >/dev/null 2>&1 \
                || ${pkgs.docker}/bin/docker network create ${lib.escapeShellArg cfg.networkName}
            '';
          };

          docker-websearch-proxy = {
            after = [
              "websearch-proxy-network.service"
              "docker-${searxngContainerName}.service"
            ];
            wants = [
              "websearch-proxy-network.service"
              "docker-${searxngContainerName}.service"
            ];
          };
        }
        // {
          "docker-${searxngContainerName}" = {
            after = ["websearch-proxy-network.service"];
            wants = ["websearch-proxy-network.service"];
          };
        }
        // lib.optionalAttrs cfg.healthcheck.enable {
          websearch-proxy-healthcheck = {
            description = "Websearch proxy HTTP healthcheck";
            after = [
              "network-online.target"
              "docker-websearch-proxy.service"
            ];
            wants = [
              "network-online.target"
              "docker-websearch-proxy.service"
            ];
            serviceConfig = {
              Type = "oneshot";
            };
            script = ''
              ${pkgs.curl}/bin/curl --fail --silent --show-error "${checkBaseUrl}/healthz" >/dev/null \
                || ${pkgs.curl}/bin/curl --fail --silent --show-error "${checkBaseUrl}" >/dev/null
            '';
          };
        };

      systemd.timers.websearch-proxy-healthcheck = lib.mkIf cfg.healthcheck.enable {
        description = "Periodic websearch proxy HTTP healthcheck";
        wantedBy = ["timers.target"];
        partOf = ["websearch-proxy-healthcheck.service"];
        timerConfig = {
          OnBootSec = "90s";
          OnUnitActiveSec = cfg.healthcheck.interval;
          Unit = "websearch-proxy-healthcheck.service";
          Persistent = true;
        };
      };

      sops.secrets = lib.optionalAttrs webSearchSecretExists {
        hermesWebSearchEnv = {
          sopsFile = webSearchSecretFile;
          format = "dotenv";
          owner = "hermes";
          group = "hermes";
          mode = "0400";
        };
      };

      services.hermes-agent = lib.mkIf hermesEnabled {
        environmentFiles = lib.mkAfter (lib.optionals webSearchSecretExists [
          config.sops.secrets.hermesWebSearchEnv.path
        ]);
        environment.FIRECRAWL_API_URL = cfg.baseUrl;
        settings.web_search = {
          enable = true;
          backend = "firecrawl";
        };
      };

      warnings = lib.optionals (!webSearchSecretExists) [
        "my.assistants.webSearch.proxy.enable is true but secrets/hermes-websearch.env.sops is missing; add TAVILY_API_KEY (and optional FIRECRAWL_API_KEY)."
      ];
    };
  };
}
