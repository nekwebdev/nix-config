{...}: {
  flake.homeModules.brave = {
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    config = lib.mkIf isLotus {
      programs.brave = {
        enable = true;
        package = pkgs.brave;
        extensions = [
          "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        ];
      };

      home.sessionVariables = {
        BROWSER = "brave";
      };
    };
  };
}
