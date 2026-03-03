{...}: {
  flake.homeModules.zedEditor = {
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    config = lib.mkIf isLotus {
      programs.zed-editor = {
        enable = true;
        extraPackages = with pkgs; [
          nil
          nixd
        ];
      };
    };
  };
}
