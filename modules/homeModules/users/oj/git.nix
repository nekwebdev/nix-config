{...}: {
  flake.homeModules.userOjGit = {
    pkgs,
    sopsUserSshKeyPath ? null,
    ...
  }: {
    assertions = [
      {
        assertion = sopsUserSshKeyPath != null;
        message = "homeModules.userOj requires `home-manager.extraSpecialArgs.sopsUserSshKeyPath` to match the SOPS user key.";
      }
    ];

    programs.git = {
      enable = true;
      package = pkgs.git;
      settings = {
        user = {
          name = "nekwebdev";
          email = "nekwebdev@users.noreply.github.com";
          signingkey = sopsUserSshKeyPath;
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
