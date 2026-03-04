{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.bare = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.hostBare];
  };

  flake.nixosModules.hostBare = {lib, ...}: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops

      self.nixosModules.base
      self.nixosModules.userBob
    ];

    networking.hostName = "bare";
    system.stateVersion = "25.11";

    # HM-first exception: bootloader configuration is system-level.
    boot.loader.grub.enable = true;
    boot.loader.grub.devices = ["nodev"];

    # HM-first exception: root filesystem declarations are system-level.
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.bob = {
      imports = [self.homeModules.userBob];
      home.username = lib.mkDefault "bob";
      home.homeDirectory = lib.mkDefault "/home/bob";
    };

    # HM-first exception: secret format selection is host-level secret plumbing.
    sops.defaultSopsFormat = "yaml";
  };
}
