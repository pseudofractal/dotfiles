# TODO

## High Priority

- Decide and lock a stable strategy for `programs.*.package` nixGL wrapping (current approach is per-program manual wrappers).
- Add a smoke-check command/script that validates key GUI apps start (`zoom`, `sioyek`, `zotero`) after `home-manager switch`.

## Medium Priority

- Remove nix evaluation warnings about deprecated `system` usage (`stdenv.hostPlatform.system` migration where still needed).
- Fix `getExe` warnings for nixGL package by switching to explicit executable selection (`lib.getExe' ...`).
- Clean up xorg deprecation warnings by replacing legacy `xorg.*` package refs with renamed attrs.

## Niceties

- Revisit generic `nixGLPackageAttrs` support for `programs.*.package` only if a recursion-safe pattern is proven.
- Add brief docs examples for additional GUI modules that use `dotfiles.graphical.nixgl.requests.home`.
