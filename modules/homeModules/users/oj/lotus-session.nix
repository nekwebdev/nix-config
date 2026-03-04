{...}: {
  flake.homeModules.userOjLotusSession = {
    config,
    lib,
    osConfig ? {},
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    # HM-first: user-scoped session variables from legacy lotus config.
    home.sessionVariables = lib.mkIf isLotus {
      CODEX_HOME = "${config.home.homeDirectory}/.config/codex";
      TERMINAL = "ghostty";
    };
  };
}
