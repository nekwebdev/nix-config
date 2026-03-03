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
          pkgs.eza
          pkgs.fzf
          pkgs.fd
          pkgs.ripgrep
          pkgs.zoxide
          pkgs.starship
          pkgs.bat
          pkgs.jq
          pkgs.direnv
          self'.packages.git
          self'.packages.jj
        ]
        ++ pkgs.lib.optionals (pkgs ? nh) [pkgs.nh];
    };
  };
}
