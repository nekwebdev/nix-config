{inputs, ...}: {
  flake.homeModules.dms = {
    lib,
    pkgs,
    ...
  }: let
    niriIncludeNames = [
      "alttab"
      "binds"
      "colors"
      "cursor"
      "layout"
      "misc"
      "outputs"
      "windowrules"
      "wpblur"
    ];

    niriIncludeSourceDir = ./niri/files;

    dmsSettings = builtins.fromJSON (builtins.readFile ./dms/settings.ref.json);

    matugenConfigToml = ./dms/matugen/config.toml;
    matugenStarshipTemplate = ./dms/matugen/templates/starship.toml;
    matugenBatTemplate = ./dms/matugen/templates/bat.tmTheme;
  in {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms-plugin-registry.modules.default
    ];

    config = {
      xdg.configFile."dms/config.toml".text = ''
        prompt = "Run"
        terminal = "foot"
      '';

      home.sessionVariables.SYS_MON = "dgop";

      programs.dank-material-shell = {
        enable = true;

        enableSystemMonitoring = true;
        enableVPN = true;
        enableDynamicTheming = true;
        enableAudioWavelength = true;
        enableCalendarEvents = true;
        enableClipboardPaste = true;

        niri = {
          enableSpawn = true;
          enableKeybinds = false;
          includes = {
            enable = true;
            override = true;
            originalFileName = "hm";
            filesToInclude = niriIncludeNames;
          };
        };

        managePluginSettings = true;
        plugins = {
          nixMonitor.enable = true;
        };

        settings = dmsSettings;
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

      home.activation.dmsSetupNiriIncludes = lib.hm.dag.entryAfter ["writeBoundary"] ''
        dms_dir="$HOME/.config/niri/dms"
        source_dir="${niriIncludeSourceDir}"
        $DRY_RUN_CMD mkdir -p "$dms_dir"

        copy_include_if_missing() {
          name="$1"
          source_file="$source_dir/$name.kdl"
          target_file="$dms_dir/$name.kdl"

          if [ -e "$target_file" ]; then
            return 0
          fi

          if [ ! -f "$source_file" ]; then
            echo "warning: missing source include template: $source_file" >&2
            return 0
          fi

          echo "Copying default Niri include: $name.kdl"
          if ! $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "$source_file" "$target_file"; then
            echo "warning: failed to copy include template for $name" >&2
          fi
        }

        for include_name in ${lib.escapeShellArgs niriIncludeNames}; do
          copy_include_if_missing "$include_name"
        done
      '';
    };
  };
}
