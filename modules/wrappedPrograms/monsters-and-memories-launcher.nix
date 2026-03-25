{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    pname = "monsters-and-memories-launcher";
    version = "0.22.14";
    appImageFile = "MonstersAndMemories_${version}_amd64.AppImage";
    src = pkgs.fetchurl {
      url = "https://pub-f06cad9ebbcd412bb0f4ff64f0f6a3d7.r2.dev/launcher_v2/${version}/${appImageFile}";
      hash = "sha256-UImtt6bokj1f1TxPLpG393AOUsL3A3ONM6Ezs1GlzeM=";
    };
    umuRunFhsShim = pkgs.writeShellScriptBin "umu-run" ''
      set -o errexit
      set -o nounset
      set -o pipefail

      # AppImage runtime vars break umu's Python interpreter and grep linkage.
      unset PYTHONHOME
      unset PYTHONPATH
      unset PYTHONDONTWRITEBYTECODE
      unset PERLLIB
      unset QT_PLUGIN_PATH
      unset GSETTINGS_SCHEMA_DIR
      unset GST_PLUGIN_SYSTEM_PATH
      unset GST_PLUGIN_SYSTEM_PATH_1_0
      unset LD_LIBRARY_PATH

      exec "${pkgs.umu-launcher}/bin/umu-run" "$@"
    '';
    appimageContents = pkgs.appimageTools.extractType2 {
      inherit pname version src;
    };
    appimageRunner = pkgs.appimage-run.override {
      extraPkgs = ps: [
        umuRunFhsShim
        ps.webkitgtk_4_1
        ps.gtk3
        ps.libsoup_3
      ];
    };
  in {
    packages.${pname} = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = appimageRunner;
      exePath = "${appimageRunner}/bin/appimage-run";
      binName = pname;
      args = [src];

      runtimeInputs = [pkgs.coreutils pkgs.gnugrep];

      patchHook = ''
        # Keep only the user-facing launcher in the wrapped output.
        rm -f "$out/bin/appimage-run"
        rm -f "$out/share/applications/appimage-run.desktop"

        # Stage the AppImage into a writable user path so the launcher does not
        # derive install dirs from the immutable Nix store path.
        install -Dm755 "${umuRunFhsShim}/bin/umu-run" "$out/libexec/${pname}/bin/umu-run"

        rm -f "$out/bin/${pname}"
        cat > "$out/bin/${pname}" <<'EOF'
        #!${pkgs.bash}/bin/bash
        set -o errexit
        set -o nounset
        set -o pipefail

        script_dir="$(cd -- "$(dirname -- "''${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
        prefix_dir="$(cd -- "$script_dir/.." >/dev/null 2>&1 && pwd)"

        export PATH="$prefix_dir/libexec/${pname}/bin:${pkgs.lib.makeBinPath [pkgs.coreutils pkgs.gnugrep]}:$PATH"
        export GAMEID="monsters-and-memories"
        export UMU_NO_RUNTIME="1"
        export UMU_RUNTIME_UPDATE="0"

        data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
        appimage_dir="$data_home/${pname}"
        appimage_path="$appimage_dir/${appImageFile}"
        mkdir -p "$appimage_dir"

        if [ ! -f "$appimage_path" ]; then
          cp "${src}" "$appimage_path"
          chmod 0755 "$appimage_path"
        fi

        exec "${appimageRunner}/bin/appimage-run" "$appimage_path" "$@"
        EOF
        chmod 0755 "$out/bin/${pname}"

        mkdir -p "$out/share/applications"
        mkdir -p "$out/share/icons/hicolor/32x32/apps"
        mkdir -p "$out/share/icons/hicolor/128x128/apps"
        mkdir -p "$out/share/icons/hicolor/256x256@2/apps"

        cp "${appimageContents}/usr/share/icons/hicolor/32x32/apps/mnm_launcher.png" \
          "$out/share/icons/hicolor/32x32/apps/${pname}.png"
        cp "${appimageContents}/usr/share/icons/hicolor/128x128/apps/mnm_launcher.png" \
          "$out/share/icons/hicolor/128x128/apps/${pname}.png"
        cp "${appimageContents}/usr/share/icons/hicolor/256x256@2/apps/mnm_launcher.png" \
          "$out/share/icons/hicolor/256x256@2/apps/${pname}.png"

        cat > "$out/share/applications/${pname}.desktop" <<EOF
        [Desktop Entry]
        Type=Application
        Name=Monsters & Memories
        Comment=A launcher and patcher for Monsters & Memories
        Exec=${pname}
        Icon=${pname}
        StartupWMClass=mnm_launcher
        Terminal=false
        Categories=Game;
        EOF
      '';
    };
  };
}
