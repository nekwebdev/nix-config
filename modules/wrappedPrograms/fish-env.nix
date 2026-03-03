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
        ]
        ++ pkgs.lib.optionals (pkgs ? nh) [pkgs.nh];
    };
  };
}
