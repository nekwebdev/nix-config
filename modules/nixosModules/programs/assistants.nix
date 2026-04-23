{inputs, ...}: {
  flake.nixosModules.assistants = {...}: {
    imports = [
      inputs.hermes-agent.nixosModules.default
    ];

    # HM-first exception: hermes-agent is a root-owned system service.
    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      settings = {
        model = {
          provider = "openai-codex";
          default = "gpt-5.4-mini";
        };
        fallback_providers = [
          {
            provider = "openai-codex";
            model = "gpt-5.3-codex";
          }
          {
            provider = "anthropic";
            model = "claude-opus-4-7";
          }
        ];
        delegation = {
          provider = "openai-codex";
          model = "gpt-5.3-codex";
        };
      };
    };
  };

  flake.homeModules.assistants = {
    config,
    lib,
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    codexConfigTemplate = "${repoRoot}/configs/common/codex/config.toml";
    claudeMcpTemplate = "${repoRoot}/configs/common/claude/.mcp.json";
    claudeSettingsTemplate = "${repoRoot}/configs/common/claude/settings.json";
    assistantConfigSyncScript = "${repoRoot}/scripts/assistants-config-sync.sh";
  in {
    # Keep assistant CLIs and assistant-specific env/config in one reusable HM module.
    home.packages = [
      pkgs.bubblewrap
      inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    home.sessionVariables = {
      CODEX_HOME = "${config.xdg.configHome}/codex";
      CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
    };

    programs.git.ignores = [
      ".codex"
      ".claude/settings.local.json"
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

    # Keep assistant runtime config additive: only write missing keys/blocks.
    home.activation.assistantRuntimeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      codex_config="${config.xdg.configHome}/codex/config.toml"
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
        ${lib.escapeShellArg codexConfigTemplate} \
        "$codex_config" \
        ${lib.escapeShellArg claudeMcpTemplate} \
        "$claude_mcp_config" \
        ${lib.escapeShellArg claudeSettingsTemplate} \
        "$claude_settings"
    '';
  };
}
