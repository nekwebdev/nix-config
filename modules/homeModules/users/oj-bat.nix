{...}: {
  flake.homeModules.userOjBat = {
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";

    batAliases = {
      brg = "${pkgs.bat-extras.batgrep}/bin/batgrep";
      cat = "${pkgs.bat}/bin/bat --paging=never";
      less = "${pkgs.bat}/bin/bat";
      more = "${pkgs.bat}/bin/bat";
    };
  in {
    config = lib.mkIf isLotus {
      home.sessionVariables = {
        MANPAGER = "sh -c 'col --no-backspaces --spaces | ${pkgs.bat}/bin/bat --language man'";
        MANROFFOPT = "-c";
        PAGER = "${pkgs.bat}/bin/bat";
      };

      programs.bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras;
          [
            batgrep
            batwatch
          ]
          ++ lib.optionals (pkgs.bat-extras ? prettybat) [prettybat];
        config = {
          style = "plain";
          theme = "dms";
        };
      };

      my.home.aliases.fragments = [
        {
          source = "homeModules.users.ojBat";
          aliases = batAliases;
        }
      ];
    };
  };
}
