{inputs, ...}: {
  flake.nixosModules.hermes = {
    config,
    lib,
    pkgs,
    ...
  }: let
    telegramSecretFile = ../../../secrets/hermes-telegram.env.sops;
    telegramSecretExists = builtins.pathExists telegramSecretFile;
    openAiSecretFile = ../../../secrets/hermes-openai.env.sops;
    openAiSecretExists = builtins.pathExists openAiSecretFile;
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
  };
}
