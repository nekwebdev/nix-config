{inputs, ...}: {
  flake.homeModules.dms = {
    lib,
    pkgs,
    ...
  }: let
    runtimeConfigHelper = ../../../scripts/runtime-config-helper.sh;
    matugenConfigToml = ../../../configs/matugen/config.toml;
    matugenStarshipTemplate = ../../../configs/matugen/templates/starship.toml;
    matugenBatTemplate = ../../../configs/matugen/templates/bat.tmTheme;
  in {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms-plugin-registry.modules.default
    ];

    config = {
      home.sessionVariables.SYS_MON = "dgop";

      # Seed runtime configs from repo configs list via shared helper.
      home.activation.dmsRuntimeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${runtimeConfigHelper} seed dms
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
