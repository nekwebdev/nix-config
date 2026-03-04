{...}: {
  flake.homeModules.base = {pkgs, ...}: {
    # Shared user-level must-have tools without per-program configuration.
    home.packages = [
      pkgs.curl
      pkgs.diff-so-fancy
      pkgs.direnv
      pkgs.fd
      pkgs.jq
      pkgs.just
      pkgs.keychain
      pkgs.ncdu
      pkgs.ripgrep
      pkgs.unzip
      pkgs.vim
      pkgs.wget
    ];
  };
}
