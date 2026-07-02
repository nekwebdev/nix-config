{...}: {
  flake.homeModules.pi = {...}: let
    piAliases = {
      # pi = "mise run pi";
    };
  in {
    my.home.aliases.fragments = [
      {
        source = "homeModules.programs.pi";
        aliases = piAliases;
      }
    ];

    programs.git.ignores = [
      ".rpiv/"
      "thoughts/"
      ".pi-lens/"
      ".pi/"
    ];
  };
}
