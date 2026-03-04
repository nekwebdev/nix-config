{...}: {
  flake.homeModules.userOjLotusSession = {config, ...}: {
    # HM-first: user-scoped session variables from legacy lotus config.
    home.sessionVariables = {
      CODEX_HOME = "${config.home.homeDirectory}/.config/codex";
      TERMINAL = "ghostty";
    };
  };
}
