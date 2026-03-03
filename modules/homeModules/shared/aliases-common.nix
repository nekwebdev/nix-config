{
  flake.homeModules.aliasesCommon = {
    my.home.aliases.fragments = [
      {
        source = "homeModules.shared.aliasesCommon";
        aliases = {
          cp = "cp -i";
          mv = "mv -i";
          mkdir = "mkdir -p";

          mx = "chmod a+x";
          "000" = "chmod -R 000";
          "600" = "chmod -R 600";
          "644" = "chmod -R 644";
          "666" = "chmod -R 666";
          "700" = "chmod -R 700";
          "755" = "chmod -R 755";
          "777" = "chmod -R 777";

          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          "......" = "cd ../../../../..";

          dir = "dir --color=auto";
          vdir = "vdir --color=auto";
          grep = "grep --color=auto";
          fgrep = "fgrep --color=auto";
          egrep = "egrep --color=auto";

          tarnow = "tar -acf";
          untar = "tar -zxvf";
          jctl = "journalctl -p 3 -xb";
        };
      }
    ];
  };
}
