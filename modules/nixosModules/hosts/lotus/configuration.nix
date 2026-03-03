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
      self.nixosModules.hostLotusPolicy
      self.nixosModules.hostLotusServices
      self.nixosModules.hostLotusNvidia
      self.nixosModules.hostLotusGaming
      self.nixosModules.hostLotusPortals
      self.nixosModules.hostLotusFlatpak
      self.nixosModules.hostLotusUdev
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
        git = self.packages.${system}.git;
      };
      # Keep aligned with secrets/recipients/users/oj.txt line 3 expected key path.
      sopsUserSshKeyPath = "/home/oj/.ssh/nixos-lotus";
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
