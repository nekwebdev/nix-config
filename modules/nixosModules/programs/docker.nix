{...}: {
  flake.nixosModules.docker = {...}: {
    virtualisation.docker = {
      # Use the system daemon here so GPU CDI devices are available to Compose services.
      enable = true;

      daemon.settings = {
        dns = ["1.1.1.1" "8.8.8.8"];
        registry-mirrors = ["https://mirror.gcr.io"];
        features = {
          cdi = true;
        };
      };

      rootless.enable = false;
    };
  };
}
