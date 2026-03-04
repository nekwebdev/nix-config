{...}: {
  flake.homeModules.userOjGit = {
    pkgs,
    config,
    osConfig ? {},
    ...
  }: {
    programs.git = {
      enable = true;
      package = pkgs.git;
      settings = {
        user = {
          name = "nekwebdev";
          email = "nekwebdev@users.noreply.github.com";
          signingkey = "${config.home.homeDirectory}/.ssh/nixos-${osConfig.networking.hostName}";
        };
        init.defaultBranch = "main";
        gpg.format = "ssh";
        commit.gpgSign = true;
        core.pager = "diff-so-fancy | less --tabs=4 -RFX";
        interactive.diffFilter = "diff-so-fancy --patch";
      };
    };
  };
}
