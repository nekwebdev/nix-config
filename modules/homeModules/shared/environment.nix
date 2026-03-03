{...}: {
  flake.homeModules.environment = {config, ...}: {
    home.sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
    ];

    home.sessionVariables = {
      XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
      EDITOR = "vim";
    };
  };
}
