{...}: {
  flake.homeModules.tlrc = {
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    config = lib.mkIf isLotus {
      home.packages = [pkgs.tlrc];

      services.tldr-update = {
        enable = true;
        package = pkgs.tlrc;
      };
    };
  };
}
