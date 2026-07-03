{...}: {
  flake.homeModules.base = {
    pkgs,
    config,
    ...
  }: {
    # Shared user-level must-have tools without per-program configuration.
    home.packages = [
      pkgs.bitwarden-cli
      pkgs.curl
      pkgs.diff-so-fancy
      pkgs.direnv
      pkgs.tree
      pkgs.fd
      pkgs.jq
      pkgs.just
      pkgs.mise
      pkgs.keychain
      pkgs.ncdu
      (pkgs.python3.withPackages (ps: [
        ps.pyyaml
      ]))
      pkgs.uv
      pkgs.ripgrep
      pkgs.unzip
      pkgs.wget
      pkgs.shellcheck
    ];

    programs.direnv = {
      enable = true;
      enableBashIntegration = config.programs.bash.enable;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable;
      nix-direnv.enable = true;
    };
  };
}
