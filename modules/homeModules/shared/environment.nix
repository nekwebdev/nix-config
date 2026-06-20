{...}: {
  flake.homeModules.environment = {config, ...}: {
    xdg.enable = true;

    home.sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
    ];

    home.sessionVariables = {
      XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
