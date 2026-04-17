{
  flake.nixosModules.nvidia = {
    config,
    lib,
    ...
  }: {
    # HM-first exception: unfree package allowance is host-level package policy.
    nixpkgs.config.allowUnfree = true;

    # HM-first exception: GPU driver selection is host kernel/hardware plumbing.
    services.xserver.enable = true;
    services.xserver.videoDrivers = ["nvidia"];
    boot.kernelParams = ["nvidia-drm.modeset=1"];

    # HM-first exception: NVIDIA kernel/userspace driver stack is system hardware configuration.
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };

    # HM-first exception: OpenGL/graphics acceleration backend is host-level hardware integration.
    hardware.graphics.enable = true;

    # HM-first exception: NVIDIA container support needs system-managed CDI definitions.
    hardware.nvidia-container-toolkit.enable = true;
    virtualisation.vmVariant.hardware.nvidia-container-toolkit.enable = lib.mkForce false;

    environment.variables = {
      __GL_SHADER_DISK_CACHE_SIZE = "12000000000";
    };
  };
}
