{...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.fish-env = pkgs.buildEnv {
      name = "fish-env";

      paths =
        [
          pkgs.curl
          pkgs.eza
          pkgs.diff-so-fancy
          pkgs.direnv
          pkgs.fd
          pkgs.fzf
          pkgs.just
          pkgs.keychain
          pkgs.ncdu
          pkgs.bat
          pkgs.jq
          pkgs.ripgrep
          pkgs.starship
          pkgs.unzip
          pkgs.vim
          pkgs.wget
          pkgs.zoxide
          self'.packages.git
        ]
        ++ pkgs.lib.optionals (pkgs ? nh) [pkgs.nh];
    };
  };
}
