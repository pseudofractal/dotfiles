---
name: neovim-configuration
description: Create, debug, or refactor Neovim configuration, Lua plugins, keybindings, language servers, and editor integrations.
---

# Neovim configuration

Inspect the installed Neovim version, configuration entry points, plugin management, and existing Lua conventions. Follow the project's configuration and packaging system when changing plugins, language servers, or external tools; do not assume an upstream plugin manager or install tools imperatively.

Trace keybindings, autocommands, and LSP configuration to their owners before editing. Check for conflicting mappings and initialization order when relevant. Validate Lua with the configured formatter or linter and use a headless Neovim check when the required runtime and plugins are available. Report what could not be exercised, including interactive behavior.

For this dotfiles repository, inspect `modules/programming/nvim/default.nix`, `modules/programming/nvim/config`, and the relevant `docs/keybinds` documentation. Account for desktop and Android differences. Update keybinding documentation when behavior changes.

A live editor is separate from the configuration on disk. Inspect or alter a running session only when the task calls for it and a suitable socket is available; preserve unsaved buffers.
