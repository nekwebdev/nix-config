{
  flake.homeModules.aliasRegistry = {
    lib,
    config,
    ...
  }: let
    fragments = config.my.home.aliases.fragments;

    entries =
      lib.concatMap (
        fragment:
          lib.mapAttrsToList (key: command: {
            inherit key command;
            source = fragment.source;
          })
          fragment.aliases
      )
      fragments;

    groupedByKey = lib.groupBy (entry: entry.key) entries;

    duplicateKeys = lib.sort builtins.lessThan (
      lib.filter (key: builtins.length groupedByKey.${key} > 1) (builtins.attrNames groupedByKey)
    );

    duplicateDetails =
      lib.concatMapStringsSep ", " (
        key: let
          defs = groupedByKey.${key};
          sources = lib.concatMapStringsSep "/" (def: def.source) defs;
        in "${key} (${sources})"
      )
      duplicateKeys;

    mergedAliases = lib.foldl' (acc: fragment: acc // fragment.aliases) {} fragments;
  in {
    options.my.home.aliases.fragments = lib.mkOption {
      default = [];
      description = "Alias fragments contributed by Home Manager modules.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              description = "Human-readable source label for this alias fragment.";
            };

            aliases = lib.mkOption {
              default = {};
              type = lib.types.attrsOf lib.types.str;
              description = "Shell alias key/value pairs contributed by this fragment.";
            };
          };
        }
      );
    };

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = duplicateKeys == [];
            message =
              "Duplicate shell alias keys detected: "
              + duplicateDetails
              + ". Keep alias keys unique across my.home.aliases.fragments.";
          }
        ];
      }

      (lib.mkIf config.programs.bash.enable {
        programs.bash.shellAliases = mergedAliases;
      })

      (lib.mkIf config.programs.fish.enable {
        programs.fish.shellAliases = mergedAliases;
      })

      (lib.mkIf config.programs.zsh.enable {
        programs.zsh.shellAliases = mergedAliases;
      })
    ];
  };
}
