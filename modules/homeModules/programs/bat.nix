{...}: {
  flake.homeModules.bat = {
    lib,
    pkgs,
    ...
  }: let
    batAliases = {
      brg = "${pkgs.bat-extras.batgrep}/bin/batgrep";
      cat = "${pkgs.bat}/bin/bat --paging=never";
      less = "${pkgs.bat}/bin/bat";
      more = "${pkgs.bat}/bin/bat";
    };
  in {
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
        source = "homeModules.programs.bat";
        aliases = batAliases;
      }
    ];
  };
}
