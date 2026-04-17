{...}: {
  flake.homeModules.git = {pkgs, ...}: {
    programs.git = {
      enable = true;
      package = pkgs.git;
      ignores = [
        ".codex/"
        ".codex"
      ];
      settings = {
        init.defaultBranch = "main";
        gpg.format = "ssh";
        commit.gpgSign = true;
        core.pager = "diff-so-fancy | less --tabs=4 -RFX";
        interactive.diffFilter = "diff-so-fancy --patch";
      };
    };
  };
}
