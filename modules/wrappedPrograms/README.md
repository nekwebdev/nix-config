# wrappedPrograms

This directory is reserved for future wrapped package modules.

Current baseline policy is module-first:
- program behavior and package selection should live in explicit Home Manager modules under `modules/homeModules/*`
- host modules should not inject wrapped package sets through `home-manager.extraSpecialArgs`

If wrappers are reintroduced later, use `wrappers.lib.wrapPackage` and document the reason in `PRD.md`.
