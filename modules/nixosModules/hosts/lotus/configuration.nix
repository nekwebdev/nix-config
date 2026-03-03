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
    pkgs,
    ...
  }: let
    system = pkgs.stdenv.hostPlatform.system;
  in {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops

      self.nixosModules.base
      self.nixosModules.hostLotusSystem
      self.nixosModules.userOj
    ];

    networking.hostName = "lotus";

    # HM-first exception: bootloader/EFI are host-level boot plumbing.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {
      wrappedPrograms = {
        fish = self.packages.${system}.fish;
        fish-env = self.packages.${system}.fish-env;
      };
    };
    home-manager.users.oj = {
      imports = [self.homeModules.userOj];
      home.username = lib.mkDefault "oj";
      home.homeDirectory = lib.mkDefault "/home/oj";
    };

    # HM-first exception: secret format selection is host-level secret plumbing.
    sops.defaultSopsFormat = "yaml";
  };
}
