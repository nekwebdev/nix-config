{
  flake.nixosModules.tailscale = {
    # HM-first exception: Tailscale is a privileged networking service.
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
  };
}
