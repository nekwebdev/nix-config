# wrappedPrograms

This directory exports wrapped packages through `perSystem.packages.*`.

Current wrappers:
- `monsters-and-memories-launcher`: pinned AppImage wrapped with `wrappers.lib.wrapPackage`, staged to `$XDG_DATA_HOME/monsters-and-memories-launcher` at runtime, executed through `appimage-run`, keeps `umu-launcher` outside the AppImage FHS PATH, defaults `UMU_NO_RUNTIME=1` + `UMU_RUNTIME_UPDATE=0`, and ships a desktop entry/icon.
  - provides `umu-run` shims that clear AppImage Python/runtime env vars before invoking the real `umu-run` (including inside appimage-run FHS `/usr/bin`).

Policy:
- keep behavior module-first in `modules/homeModules/*`
- use wrappers only for package-level wrapping (`wrappers.lib.wrapPackage`)
- do not pass wrapper sets through `home-manager.extraSpecialArgs`
