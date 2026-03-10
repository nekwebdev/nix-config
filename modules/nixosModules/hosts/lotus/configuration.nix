{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.lotus = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.hostLotus];
  };

  flake.nixosModules.hostLotus = {lib, ...}: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.nix-sweep.nixosModules.default

      self.nixosModules.base
      self.nixosModules.system
      self.nixosModules.policy
      self.nixosModules.services
      self.nixosModules.nvidia
      self.nixosModules.gaming
      self.nixosModules.portals
      self.nixosModules.flatpak
      self.nixosModules.udev
      self.nixosModules.niri
      self.nixosModules.dmsGreeter
      self.nixosModules.docker
      self.nixosModules.userOj
    ];

    networking.hostName = "lotus";
    system.stateVersion = "25.11";

    # HM-first exception: locale/timezone define host identity.
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "Pacific/Tahiti";

    # HM-first exception: resolver behavior is host networking plumbing.
    services.resolved.enable = lib.mkForce false;

    # HM-first exception: bootloader/EFI are host-level boot plumbing.
    boot.loader.systemd-boot.enable = true;
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
    home-manager.users.oj = {
      imports = [self.homeModules.ojNiri];
      home.username = lib.mkDefault "oj";
      home.homeDirectory = lib.mkDefault "/home/oj";
    };

    # HM-first exception: greeter wiring and monitor layout are host login/session plumbing.
    programs.dank-material-shell.greeter.configHome = "/home/oj";
    environment.etc."greetd/niri_overrides.kdl".text = ''
      output "DP-2" {
        position x=0 y=0
        scale 1
      }

      output "DP-1" {
        position x=5120 y=0
        scale 1
      }
    '';

    # HM-first exception: secret format selection is host-level secret plumbing.
    sops.defaultSopsFormat = "yaml";
  };
}
