{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    pname = "pinokio";
    version = "7.0.0";
    appImageFile = "Pinokio-${version}.AppImage";
    src = pkgs.fetchurl {
      url = "https://github.com/pinokiocomputer/pinokio/releases/download/v${version}/${appImageFile}";
      hash = "sha256-Sqv0afLBDo+MadtXxd2dBmqjLY5me3vlvzjSpRwJcZo=";
    };
    appimageContents = pkgs.appimageTools.extractType2 {
      inherit pname version src;
    };
  in {
    packages.${pname} = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.appimage-run;
      exePath = "${pkgs.appimage-run}/bin/appimage-run";
      binName = pname;
      args = [src];

      patchHook = ''
        # Keep only the user-facing launcher in the wrapped output.
        rm -f "$out/bin/appimage-run"
        rm -f "$out/share/applications/appimage-run.desktop"

        icon_source="$(${pkgs.findutils}/bin/find -L "${appimageContents}" \
          \( -path '*/usr/share/icons/hicolor/*/apps/*' -o -name '.DirIcon' \) \
          -type f | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/tail -n 1 || true)"

        if [ -n "$icon_source" ]; then
          icon_ext=''${icon_source##*.}
          case "$icon_ext" in
            png|svg|xpm) ;;
            *) icon_ext="png" ;;
          esac

          install -Dm644 "$icon_source" "$out/share/pixmaps/${pname}.$icon_ext"
        fi

        mkdir -p "$out/share/applications"
        cat > "$out/share/applications/${pname}.desktop" <<EOF
        [Desktop Entry]
        Type=Application
        Name=Pinokio
        Comment=AI Browser
        Exec=${pname} %U
        Icon=${pname}
        Terminal=false
        Categories=Development;Utility;
        EOF
      '';
    };
  };
}
