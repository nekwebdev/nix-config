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

    niriIncludeSourceDir = ../niri/files;

    matugenConfigToml = ./matugen/config.toml;
    matugenStarshipTemplate = ./matugen/templates/starship.toml;
    matugenBatTemplate = ./matugen/templates/bat.tmTheme;
  in {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms-plugin-registry.modules.default
    ];

    config = {
      home.sessionVariables.SYS_MON = "dgop";

      # DMS updates these files at runtime, so link runtime paths to writable repo files.
      home.activation.dmsRuntimeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        dms_runtime_dir="$HOME/.config/DankMaterialShell"
        repo_settings_rel="modules/homeModules/desktop/dms/settings.json"
        repo_plugin_rel="modules/homeModules/desktop/dms/plugin_settings.json"
        settings_target="$dms_runtime_dir/settings.json"
        plugin_target="$dms_runtime_dir/plugin_settings.json"
        find_repo_root() {
          local target current abs_current candidate_root candidate

          for target in "$settings_target" "$plugin_target"; do
            if [ ! -L "$target" ]; then
              continue
            fi

            current="$(${pkgs.coreutils}/bin/readlink "$target")"
            case "$current" in
              /nix/store/*)
                continue
                ;;
            esac

            if [[ "$current" = /* ]]; then
              abs_current="$current"
            else
              abs_current="$(${pkgs.coreutils}/bin/realpath -m "$dms_runtime_dir/$current")"
            fi

            case "$abs_current" in
              */$repo_settings_rel)
                candidate_root="''${abs_current%/$repo_settings_rel}"
                ;;
              */$repo_plugin_rel)
                candidate_root="''${abs_current%/$repo_plugin_rel}"
                ;;
              *)
                candidate_root=""
                ;;
            esac

            if [ -n "$candidate_root" ] && [ -f "$candidate_root/flake.nix" ]; then
              echo "$candidate_root"
              return 0
            fi
          done

          while IFS= read -r candidate; do
            candidate_root="''${candidate%/$repo_settings_rel}"
            if [ -f "$candidate_root/$repo_plugin_rel" ] && [ -f "$candidate_root/flake.nix" ]; then
              echo "$candidate_root"
              return 0
            fi
          done < <(${pkgs.findutils}/bin/find "$HOME" -maxdepth 8 -type f -path "*/$repo_settings_rel" 2>/dev/null)

          return 1
        }

        repo_root="$(find_repo_root || true)"
        if [ -z "$repo_root" ]; then
          echo "error: unable to locate nixos repo root for DMS runtime config symlinks" >&2
          exit 1
        fi

        settings_source="$repo_root/$repo_settings_rel"
        plugin_source="$repo_root/$repo_plugin_rel"

        if [ ! -f "$settings_source" ] || [ ! -f "$plugin_source" ]; then
          echo "error: DMS settings sources are missing in repo root: $repo_root" >&2
          exit 1
        fi

        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$dms_runtime_dir"

        if [ -e "$settings_target" ] && [ ! -L "$settings_target" ]; then
          echo "error: refusing to replace non-symlink $settings_target; migrate/remove it manually" >&2
          exit 1
        fi

        if [ -e "$plugin_target" ] && [ ! -L "$plugin_target" ]; then
          echo "error: refusing to replace non-symlink $plugin_target; migrate/remove it manually" >&2
          exit 1
        fi

        $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$settings_source" "$settings_target"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$plugin_source" "$plugin_target"
      '';

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
