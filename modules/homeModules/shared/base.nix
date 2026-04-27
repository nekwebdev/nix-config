{...}: {
  flake.homeModules.base = {
    pkgs,
    lib,
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
      pkgs.keychain
      pkgs.ncdu
      (pkgs.python3.withPackages (ps: [
        ps.pyyaml
      ]))
      pkgs.ripgrep
      pkgs.unzip
      pkgs.vim
      pkgs.wget
    ];

    programs.direnv = {
      enable = true;
      enableBashIntegration = config.programs.bash.enable;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable;
      nix-direnv.enable = true;
    };

    home.activation.bootstrapPasswordReminder = lib.hm.dag.entryAfter ["writeBoundary"] ''
      state_dir="$HOME/.local/state/nix"
      reminder_file="$state_dir/password-bootstrap-reminder"
      ack_file="$state_dir/password-bootstrap-ack"

      $DRY_RUN_CMD mkdir -p "$state_dir"
      if [ ! -f "$ack_file" ]; then
        $DRY_RUN_CMD touch "$reminder_file"
      fi
    '';
  };
}
