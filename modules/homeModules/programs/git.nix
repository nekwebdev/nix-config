{...}: {
  flake.homeModules.git = {
    pkgs,
    lib,
    config,
    ...
  }: let
    allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
    signingKeyPath = config.programs.git.settings.user.signingkey or "";
    signerPrincipal =
      config.programs.git.settings.user.email
      or config.programs.git.settings.user.name
      or "git";
  in {
    programs.git = {
      enable = true;
      package = pkgs.git;
      settings = {
        init.defaultBranch = "main";
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = allowedSignersFile;
        commit.gpgSign = true;
        core.pager = "diff-so-fancy | less --tabs=4 -RFX";
        interactive.diffFilter = "diff-so-fancy --patch";
      };
    };

    home.activation.gitAllowedSigners = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -n ${lib.escapeShellArg signingKeyPath} ] && [ -f ${lib.escapeShellArg "${signingKeyPath}.pub"} ]; then
        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/git"}
        key="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg "${signingKeyPath}.pub"})"
        ${pkgs.coreutils}/bin/printf '%s %s\n' ${lib.escapeShellArg signerPrincipal} "$key" > ${lib.escapeShellArg allowedSignersFile}
      fi
    '';
  };
}
