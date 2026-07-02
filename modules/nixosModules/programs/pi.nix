{...}: {
  flake.nixosModules.pi = {
    lib,
    pkgs,
    ...
  }: let
    piLessYolo = {
      user = "oj";
      group = "oj";
      home = "/home/oj";
      repo = "https://github.com/cjermain/pi-less-yolo";
      target = "/home/oj/.local/lib/pi-less-yolo";
    };
    piLessYoloMiseConfig = "/home/oj/.config/mise/conf.d/pi-less-yolo.toml";
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
    # Ensure mise is available system-wide even if another module also adds it.
    environment.systemPackages = [
      pkgs.mise
      pkgs.ffmpeg
      pkgs.yt-dlp
    ];

    system.activationScripts.piLessYoloClone = piLessYoloCloneScript;
  };
}
