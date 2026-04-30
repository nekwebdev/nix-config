{inputs, ...}: {
  flake.nixosModules.assistants = {
    config,
    lib,
    pkgs,
    ...
  }: let
    telegramSecretFile = ../../../secrets/hermes-telegram.env.sops;
    telegramSecretExists = builtins.pathExists telegramSecretFile;
  in {
    imports = [
      inputs.hermes-agent.nixosModules.default
      inputs.sops-nix.nixosModules.sops
    ];

    # HM-first exception: hermes-agent is a root-owned system service.
    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      mcpServers = {
        ms365 = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@softeria/ms-365-mcp-server"
            "--org-mode"
            "--preset"
            "mail"
          ];
        };
      };
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
        auxiliary = {
          compression = {
            provider = "openai-codex";
            model = "gpt-5.1-codex-mini";
          };
          web_extract = {
            provider = "openai-codex";
            model = "gpt-5.1-codex-mini";
          };
          approval = {
            provider = "openai-codex";
            model = "gpt-5.1-codex-mini";
          };
          session_search = {
            provider = "openai-codex";
            model = "gpt-5.1-codex-mini";
          };
          skills_hub = {
            provider = "openai-codex";
            model = "gpt-5.1-codex-mini";
          };
          mcp = {
            provider = "openai-codex";
            model = "gpt-5.1-codex-mini";
          };
        };
      };
    };

    sops.secrets = lib.optionalAttrs telegramSecretExists {
      hermesTelegramEnv = {
        sopsFile = telegramSecretFile;
        format = "dotenv";
        owner = "hermes";
        group = "hermes";
        mode = "0400";
      };
    };

    services.hermes-agent.environmentFiles = lib.optionals telegramSecretExists [
      config.sops.secrets.hermesTelegramEnv.path
    ];

    warnings = lib.optionals (!telegramSecretExists) [
      "secrets/hermes-telegram.env.sops is missing; create it with Telegram bot gateway dotenv values for hermes-agent runtime."
    ];
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
