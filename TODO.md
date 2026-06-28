# TODO

## High Priority

- Add a smoke-check command/script that validates key GUI apps start (`zoom`, `sioyek`, `zotero`) after `home-manager switch`.

## Medium Priority

- Nix evaluation warnings: all are upstream `mkRenamedOptionModule` traces from catppuccin and home-manager (catppuccin.vscode.profiles, fonts.fontconfig, programs.aerospace, programs.anki, etc.). Config already uses correct new names — wait for upstream to remove backward-compat aliases.

## Niceties

- Revisit generic `nixGLPackageAttrs` support for `programs.*.package` only if a recursion-safe pattern is proven.
