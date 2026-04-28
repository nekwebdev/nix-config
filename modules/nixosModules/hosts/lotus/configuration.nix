{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.lotus = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.hostLotus];
  };

  flake.nixosModules.hostLotus = {
    lib,
    config,
    pkgs,
    ...
  }: let
    primaryUser =
      if config.my.primaryUser == null
      then null
      else lib.attrByPath ["my" "users" config.my.primaryUser] null config;
  in {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-sweep.nixosModules.default

      self.nixosModules.system
      self.nixosModules.assistants
      self.nixosModules.websearchProxy
      self.nixosModules.policy
      self.nixosModules.services
      self.nixosModules.tailscale
      self.nixosModules.hostLotusHardware
      self.nixosModules.nvidia
      self.nixosModules.gaming
      self.nixosModules.portals
      self.nixosModules.flatpak
      self.nixosModules.udev
      self.nixosModules.niri
      self.nixosModules.dmsGreeter
      self.nixosModules.docker
      self.nixosModules.virtualization
      self.nixosModules.userOj
    ];

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = primaryUser != null;
            message = "hostLotus requires my.primaryUser to reference a declared my.users entry.";
          }
        ];

        my.primaryUser = "oj";

        # Age identity is provisioned manually on this machine.
        # Backup of private key is handled manually in Bitwarden (no bw CLI automation).
        sops.age.sshKeyPaths = [
          "/home/oj/.ssh/nixos-sops"
        ];

        my.assistants.webSearch.proxy = {
          enable = true;
          host = "127.0.0.1";
          port = 8082;
          baseUrl = "http://127.0.0.1:8082";
          image = "ghcr.io/nekwebdev/websearch-proxy";
          tag = "0.1.3";
          searxng = {
            image = "ghcr.io/nekwebdev/websearch-searxng";
            tag = "2026.4.24-a7ac696b4";
          };
          logLevel = "INFO";
          routeDecisionLogging = true;
          tavily = {
            dailySoftCapCalls = 6;
            monthlyCapCalls = 100;
            reservePercentCritical = 30;
          };
          healthcheck = {
            enable = true;
            interval = "2m";
          };
        };

        networking.hostName = "lotus";
        system.stateVersion = "25.11";

        # HM-first exception: locale/timezone define host identity.
        i18n.defaultLocale = "en_US.UTF-8";
        time.timeZone = "Pacific/Tahiti";

        # HM-first exception: resolver behavior is host networking plumbing.
        services.resolved.enable = lib.mkForce false;

        # HM-first exception: bootloader/EFI are host-level boot plumbing.
        boot.loader.systemd-boot.enable = true;
        boot.loader.systemd-boot.configurationLimit = 20;
        boot.loader.efi.canTouchEfiVariables = true;

        # HM-first exception: this is a root-owned maintenance service.
        services.nix-sweep = {
          enable = true;
          interval = "daily";
          gc = true;
          gcInterval = "weekly";
          profiles = [
            "system"
          ];
          keepNewer = "7d";
          removeOlder = "30d";
          keepMin = 10;
        };

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }

      (lib.mkIf (primaryUser != null) (let
        niriOutputsPath = ../../../../configs/users/${primaryUser.username}/hosts/${config.networking.hostName}/niri/outputs.kdl;
        niriOutputsRaw = builtins.readFile niriOutputsPath;
        stripModeLine = line:
          if builtins.match ''^[[:space:]]*mode[[:space:]]+".*"[[:space:]]*$'' line != null
          then ""
          else line;
      in {
        # HM-first exception: initrd secret material is host bootloader plumbing.
        system.preSwitchChecks.initrdSshHostKey = ''
          if [ "$2" = "switch" ] || [ "$2" = "boot" ]; then
            ${pkgs.coreutils}/bin/install -d -m 0700 /etc/secrets/initrd

            if [ ! -s /etc/secrets/initrd/ssh_host_ed25519_key ]; then
              ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key >/dev/null
            fi

            ${pkgs.coreutils}/bin/chmod 0600 /etc/secrets/initrd/ssh_host_ed25519_key
            ${pkgs.coreutils}/bin/chmod 0644 /etc/secrets/initrd/ssh_host_ed25519_key.pub
          fi
        '';

        # HM-first exception: initrd networking/SSH unlock is host boot plumbing.
        boot.initrd.network = {
          enable = true;
          udhcpc.enable = lib.mkIf (!config.boot.initrd.systemd.enable) true;
          ssh = {
            enable = true;
            port = 2222;
            # systemd stage-1 no longer provides cryptsetup-askpass.
            shell = lib.mkIf (!config.boot.initrd.systemd.enable) "/bin/cryptsetup-askpass";
            hostKeys = lib.optional config.boot.loader.supportsInitrdSecrets "/etc/secrets/initrd/ssh_host_ed25519_key";
            ignoreEmptyHostKeys = !config.boot.loader.supportsInitrdSecrets;
            authorizedKeyFiles = [
              ../../../../configs/users/${primaryUser.username}/hosts/${config.networking.hostName}/ssh/initrd_authorized_keys
            ];
          };
        };

        home-manager.users = {
          ${primaryUser.username} = {
            imports = [self.homeModules.${primaryUser.profileModule}];
            home.username = lib.mkDefault primaryUser.username;
            home.homeDirectory = lib.mkDefault primaryUser.homeDirectory;
          };
        };

        # HM-first exception: greeter wiring and monitor layout are host login/session plumbing.
        programs.dank-material-shell.greeter.configHome = primaryUser.homeDirectory;
        environment.etc."greetd/niri_overrides.kdl".text = lib.concatStringsSep "\n" (
          map stripModeLine (lib.splitString "\n" niriOutputsRaw)
        );
      }))
    ];
  };
}
