{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.bare = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.hostBare];
  };

  flake.nixosModules.hostBare = {
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
      self.nixosModules.userBob
    ];

    networking.hostName = "bare";
    system.stateVersion = "25.11";

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {
      wrappedPrograms = {
        fish = self.packages.${system}.fish;
        fish-env = self.packages.${system}.fish-env;
      };
    };
    home-manager.users.bob = {
      imports = [self.homeModules.userBob];
      home.username = lib.mkDefault "bob";
      home.homeDirectory = lib.mkDefault "/home/bob";
    };

    # HM-first exception: secret format selection is host-level secret plumbing.
    sops.defaultSopsFormat = "yaml";
  };
}
