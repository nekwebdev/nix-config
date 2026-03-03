{
  flake.nixosModules.hostLotus = {lib, ...}: {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
