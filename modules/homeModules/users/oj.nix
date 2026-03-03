{self, ...}: {
  flake.homeModules.userOj = {
    wrappedPrograms,
    sopsUserSshKeyPath ? null,
    ...
  }: {
    imports = [
      self.homeModules.fishEnv
      self.homeModules.aliasRegistry
      self.homeModules.aliasesCommon
    ];

    assertions = [
      {
        assertion = sopsUserSshKeyPath != null;
        message = "homeModules.userOj requires `home-manager.extraSpecialArgs.sopsUserSshKeyPath` to match the SOPS user key.";
      }
    ];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;

    programs.git = {
      enable = true;
      package = wrappedPrograms.git;
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
