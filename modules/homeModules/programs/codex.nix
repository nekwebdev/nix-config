{inputs, ...}: {
  flake.homeModules.codex = {
    config,
    lib,
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    codexConfigTemplate = "${repoRoot}/configs/common/codex/config.toml";
    assistantConfigSyncScript = "${repoRoot}/scripts/assistants-config-sync.sh";
  in {
    home.packages = [
      pkgs.bubblewrap
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    home.sessionVariables = {
      CODEX_HOME = "${config.xdg.configHome}/codex";
    };

    programs.git.ignores = [
      ".codex"
    ];

    # Declarative policy memory: enforced from repo on each switch.
    xdg.configFile."codex/memories/git-signing-preference.md" = {
      force = true;
      source = ../../../configs/common/codex/memories/git-signing-preference.md;
    };

    xdg.configFile."codex/rules/nix-safe.rules" = {
      force = true;
      source = ../../../configs/common/codex/rules/nix-safe.rules;
    };

    # Keep Codex runtime config additive: only write missing keys/blocks.
    home.activation.codexRuntimeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      codex_config="${config.xdg.configHome}/codex/config.toml"
      assistant_sync_path="${lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        pkgs.diffutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.gnused
        pkgs.jq
      ]}"

      PATH="$assistant_sync_path:$PATH" ${pkgs.bash}/bin/bash ${lib.escapeShellArg assistantConfigSyncScript} \
        codex \
        ${lib.escapeShellArg codexConfigTemplate} \
        "$codex_config"
    '';
  };
}
