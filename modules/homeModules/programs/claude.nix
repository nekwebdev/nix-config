{inputs, ...}: {
  flake.homeModules.claude = {
    config,
    lib,
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    claudeMcpTemplate = "${repoRoot}/configs/common/claude/.mcp.json";
    claudeSettingsTemplate = "${repoRoot}/configs/common/claude/settings.json";
    assistantConfigSyncScript = "${repoRoot}/scripts/assistants-config-sync.sh";
  in {
    home.packages = [
      inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    home.sessionVariables = {
      CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
    };

    programs.git.ignores = [
      ".claude/settings.local.json"
    ];

    # Keep Claude runtime config additive: only write missing keys/blocks.
    home.activation.claudeRuntimeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      claude_config_dir="${config.xdg.configHome}/claude"
      claude_mcp_config="$claude_config_dir/.mcp.json"
      claude_settings="$claude_config_dir/settings.json"
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
        claude \
        ${lib.escapeShellArg claudeMcpTemplate} \
        "$claude_mcp_config" \
        ${lib.escapeShellArg claudeSettingsTemplate} \
        "$claude_settings"
    '';
  };
}
