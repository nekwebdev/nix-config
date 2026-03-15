{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    pname = "orca-slicer";
  in {
    packages.${pname} = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.orca-slicer;
      exePath = "${pkgs.orca-slicer}/bin/orca-slicer";
      binName = pname;
      env = {
        __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
        __GLX_VENDOR_LIBRARY_NAME = "mesa";
        GALLIUM_DRIVER = "zink";
        GBM_BACKEND = "dri";
        GDK_DPI_SCALE = "1";
        GDK_SCALE = "1";
        MESA_LOADER_DRIVER_OVERRIDE = "zink";
        WEBKIT_DISABLE_COMPOSITING_MODE = "1";
        WEBKIT_DISABLE_DMABUF_RENDERER = "1";
      };
    };
  };
}
