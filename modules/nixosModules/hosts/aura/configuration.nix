{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.aura = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.hostAura];
  };

  flake.nixosModules.hostAura = {
    lib,
    config,
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
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.preservation

      self.nixosModules.system
      self.nixosModules.policy
      self.nixosModules.services
      self.nixosModules.tailscale
      self.nixosModules.hostAuraDisko
      self.nixosModules.hostAuraHardware
      self.nixosModules.hostAuraPreservation
      self.nixosModules.gaming
      self.nixosModules.portals
      self.nixosModules.flatpak
      self.nixosModules.udev
      self.nixosModules.niri
      self.nixosModules.dmsGreeter
      self.nixosModules.userOj
    ];

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = primaryUser != null;
            message = "hostAura requires my.primaryUser to reference a declared my.users entry.";
          }
        ];

        my.primaryUser = "oj";
        my.users.oj.profileModule = "ojAuraProfile";

        # HM-first exception: Steam, Discord, and browser packages require unfree package policy.
        nixpkgs.config.allowUnfree = true;

        networking.hostName = "aura";
        system.stateVersion = "25.11";

        # HM-first exception: locale/timezone define host identity.
        i18n.defaultLocale = "en_US.UTF-8";
        time.timeZone = "Pacific/Tahiti";

        # HM-first exception: resolver behavior is host networking plumbing.
        services.resolved.enable = lib.mkForce false;

        # HM-first exception: laptop firmware updates and Intel thermal policy are host hardware services.
        services.fwupd.enable = true;
        services.thermald.enable = true;

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
        home-manager.users = {
          ${primaryUser.username} = {
            imports = [
              self.homeModules.${primaryUser.profileModule}
              self.homeModules.codex
            ];
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
