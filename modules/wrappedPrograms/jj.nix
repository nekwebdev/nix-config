{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.jj =
      if pkgs ? jj
      then
        inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.jj;
        }
      else if pkgs ? jujutsu
      then
        inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.jujutsu;
        }
      else throw "Neither pkgs.jj nor pkgs.jujutsu is available for packages.jj";
  };
}
