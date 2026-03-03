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

      self.nixosModules.base
      self.nixosModules.userOj
    ];

    networking.hostName = "lotus";
    system.stateVersion = "24.11";

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
  };
}
