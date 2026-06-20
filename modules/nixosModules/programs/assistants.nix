{inputs, ...}: {
  flake.nixosModules.assistants = {
    config,
    lib,
    pkgs,
    ...
  }: let
    telegramSecretFile = ../../../secrets/hermes-telegram.env.sops;
    telegramSecretExists = builtins.pathExists telegramSecretFile;
    openAiSecretFile = ../../../secrets/hermes-openai.env.sops;
    openAiSecretExists = builtins.pathExists openAiSecretFile;
    piLessYolo = {
      user = "oj";
      group = "oj";
      home = "/home/oj";
      repo = "https://github.com/cjermain/pi-less-yolo";
      target = "/home/oj/.local/lib/pi-less-yolo";
    };
    piLessYoloMiseConfig = "/home/oj/.config/mise/conf.d/pi-less-yolo.toml";
    mkHermesSecret = name: file: {
      ${name} = {
        sopsFile = file;
        format = "dotenv";
        owner = "hermes";
        group = "hermes";
        mode = "0400";
        restartUnits = ["hermes-agent.service"];
      };
    };
    piLessYoloCloneScript = ''
      target=${lib.escapeShellArg piLessYolo.target}
      repo=${lib.escapeShellArg piLessYolo.repo}
      user=${lib.escapeShellArg piLessYolo.user}
      group=${lib.escapeShellArg piLessYolo.group}
      mise_config=${lib.escapeShellArg piLessYoloMiseConfig}

      if [ ! -d "$target/.git" ]; then
        if [ -e "$target" ]; then
          ${pkgs.coreutils}/bin/rm -rf "$target"
        fi

        ${pkgs.coreutils}/bin/install -d -m 0755 -o "$user" -g "$group" ${lib.escapeShellArg "${piLessYolo.home}/.local/lib"}
        ${pkgs.util-linux}/bin/runuser -u "$user" -- ${pkgs.bash}/bin/bash -euo pipefail -c '
          repo="$1"
          target="$2"
          ${pkgs.git}/bin/git clone "$repo" "$target"
        ' _ "$repo" "$target"
      fi

      if [ ! -e "$mise_config" ]; then
        ${pkgs.util-linux}/bin/runuser -u "$user" -- ${pkgs.bash}/bin/bash -euo pipefail -c '
          cd "$1"
          ${pkgs.mise}/bin/mise trust
          ${pkgs.mise}/bin/mise run install
          ${pkgs.mise}/bin/mise run pi:build
        ' _ "$target"
      fi
    '';
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
          model = "gpt-5.5";
          max_iterations = 100;
          child_timeout_seconds = 1200;
        };
        auxiliary = {
          compression = {
            # Use the direct OpenAI API for compression so we get the full
            # context window from the OpenAI key, while leaving the main
            # openai-codex provider on OAuth for normal model calls.
            # provider = "main";
            # model = "gpt-5.5";
            # base_url = "https://api.openai.com/v1";
            # api_key = "$" + "{OPENAI_API_KEY}";
            provider = "openai-codex";
            model = "gpt-5.3-codex";
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
        memory = {
          provider = "holographic";
        };
      };
    };

    sops.secrets =
      lib.optionalAttrs telegramSecretExists (mkHermesSecret "hermesTelegramEnv" telegramSecretFile)
      // lib.optionalAttrs openAiSecretExists (mkHermesSecret "hermesOpenAIEnv" openAiSecretFile);

    services.hermes-agent.environmentFiles =
      lib.optionals telegramSecretExists [
        config.sops.secrets.hermesTelegramEnv.path
      ]
      ++ lib.optionals openAiSecretExists [
        config.sops.secrets.hermesOpenAIEnv.path
      ];

    warnings =
      lib.optionals (!telegramSecretExists) [
        "secrets/hermes-telegram.env.sops is missing; create it with Telegram bot gateway dotenv values for hermes-agent runtime."
      ]
      ++ lib.optionals (!openAiSecretExists) [
        "secrets/hermes-openai.env.sops is missing; create it with OPENAI_API_KEY for direct OpenAI auxiliary tasks like compression."
      ];

    # Ensure mise is available system-wide even if another module also adds it.
    environment.systemPackages = [
      pkgs.mise
      pkgs.ffmpeg
      pkgs.yt-dlp
    ];

    system.activationScripts.piLessYoloClone = piLessYoloCloneScript;
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
    assistantAliases = {
      # pi = "mise run pi";
    };
  in {
    # Keep assistant CLIs and assistant-specific env/config in one reusable HM module.
    home.packages = [
      pkgs.bubblewrap
      inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    my.home.aliases.fragments = [
      {
        source = "homeModules.programs.assistants";
        aliases = assistantAliases;
      }
    ];

    home.sessionVariables = {
      CODEX_HOME = "${config.xdg.configHome}/codex";
      CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
    };

    programs.git.ignores = [
      ".codex"
      ".claude/settings.local.json"
      ".rpiv/"
      "thoughts/"
      ".pi-lens/"
      ".pi/"
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
