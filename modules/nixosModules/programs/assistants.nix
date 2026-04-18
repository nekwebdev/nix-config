{inputs, ...}: {
  flake.nixosModules.assistants = {lib, ...}: {
    config = {
      # HM-first exception: package-set overlays are host-level composition plumbing.
      nixpkgs.overlays = lib.mkAfter [
        (_final: prev: {
          claude-code = inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.default;
          codex-cli = inputs.codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
        })
      ];
    };
  };

  flake.homeModules.assistants = {
    config,
    pkgs,
    ...
  }: {
    # Keep assistant CLIs and assistant-specific env/config in one reusable HM module.
    home.packages = [
      pkgs.bubblewrap
      pkgs.claude-code
      pkgs.codex-cli
    ];

    home.sessionVariables = {
      CODEX_HOME = "${config.xdg.configHome}/codex";
      CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
    };

    programs.git.ignores = [
      ".codex/"
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
  };
}
