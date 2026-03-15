# wrappedPrograms

This directory exports wrapped packages through `perSystem.packages.*`.

Current wrappers:
- `monsters-and-memories-launcher`: pinned AppImage wrapped with `wrappers.lib.wrapPackage`, staged to `$XDG_DATA_HOME/monsters-and-memories-launcher` at runtime, executed through `appimage-run`, keeps `umu-launcher` outside the AppImage FHS PATH, defaults `UMU_NO_RUNTIME=1` + `UMU_RUNTIME_UPDATE=0`, and ships a desktop entry/icon.
  - provides `umu-run` shims that clear AppImage Python/runtime env vars before invoking the real `umu-run` (including inside appimage-run FHS `/usr/bin`).
- `orca-slicer`: wraps nixpkgs OrcaSlicer binary with a compatibility profile for problematic Wayland/NVIDIA stacks (`__GLX_VENDOR_LIBRARY_NAME=mesa`, `MESA_LOADER_DRIVER_OVERRIDE=zink`, `GALLIUM_DRIVER=zink`, `WEBKIT_DISABLE_DMABUF_RENDERER=1`, `WEBKIT_DISABLE_COMPOSITING_MODE=1`).

Policy:
- keep behavior module-first in `modules/homeModules/*`
- use wrappers only for package-level wrapping (`wrappers.lib.wrapPackage`)
- do not pass wrapper sets through `home-manager.extraSpecialArgs`
