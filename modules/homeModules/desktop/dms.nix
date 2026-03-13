{inputs, ...}: {
  flake.homeModules.dms = {
    config,
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    runtimeConfigHelper = "${repoRoot}/scripts/runtime-config-helper.sh";
    runtimeUser = config.home.username or "";
    runtimeHost = osConfig.networking.hostName or "";
    matugenConfigToml = "${repoRoot}/configs/common/matugen/config.toml";
    matugenStarshipTemplate = "${repoRoot}/configs/common/matugen/templates/starship.toml";
    matugenBatTemplate = "${repoRoot}/configs/common/matugen/templates/bat.tmTheme";
  in {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms-plugin-registry.modules.default
    ];

    config = {
      home.sessionVariables.SYS_MON = "dgop";

      # Seed runtime configs from repo configs list via shared helper.
      home.activation.dmsRuntimeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/env \
          RUNTIME_CONFIG_USER=${lib.escapeShellArg runtimeUser} \
          RUNTIME_CONFIG_HOST=${lib.escapeShellArg runtimeHost} \
          ${pkgs.bash}/bin/bash ${runtimeConfigHelper} seed dms
      '';

      programs.dank-material-shell = {
        enable = true;

        enableSystemMonitoring = true;
        enableVPN = true;
        enableDynamicTheming = true;
        enableAudioWavelength = true;
        enableCalendarEvents = true;
        enableClipboardPaste = true;
      };

      # Matugen templates are runtime inputs and must be plain files, not HM symlinks.
      home.activation.dmsMatugenTemplates = lib.hm.dag.entryAfter ["writeBoundary"] ''
        config_dir="$HOME/.config/matugen"
        template_dir="$config_dir/templates"

        ${pkgs.coreutils}/bin/mkdir -p "$template_dir"
        ${pkgs.coreutils}/bin/rm -f "$config_dir/config.toml"
        ${pkgs.coreutils}/bin/rm -f "$template_dir/bat.tmTheme"
        ${pkgs.coreutils}/bin/rm -f "$template_dir/starship.toml"
        ${pkgs.coreutils}/bin/install -m 0644 ${matugenConfigToml} "$config_dir/config.toml"
        ${pkgs.coreutils}/bin/install -m 0644 ${matugenBatTemplate} "$template_dir/bat.tmTheme"
        ${pkgs.coreutils}/bin/install -m 0644 ${matugenStarshipTemplate} "$template_dir/starship.toml"
      '';
    };
  };
}
