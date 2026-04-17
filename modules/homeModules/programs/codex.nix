{inputs, ...}: {
  flake.homeModules.codex = {
    config,
    pkgs,
    ...
  }: {
    # Keep Codex CLI and CODEX_HOME managed in one reusable HM module.
    home.packages = [
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    home.sessionVariables = {
      CODEX_HOME = "${config.xdg.configHome}/codex";
    };

    # Declarative policy memory: enforced from repo on each switch.
    xdg.configFile."codex/memories/git-signing-preference.md" = {
      force = true;
      source = ../../../configs/common/codex/memories/git-signing-preference.md;
    };
  };
}
