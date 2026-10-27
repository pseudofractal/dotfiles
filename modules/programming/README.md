# Coding agents

OpenCode, Codex, and Claude Code share instructions, skills, and MCP servers.
T3 Code nightly is the desktop interface to those same configured CLIs. It is
disabled on Android; the terminal agents remain available there.

## Edit once, apply to all agents

- `shared/instructions.md`: global behavioral instructions. Home Manager writes
  the same content to Codex's `AGENTS.md`, Claude's `CLAUDE.md`, and OpenCode's
  instruction file. Repository instructions still work normally.
- `shared/skills.nix`: one named collection of skill sources, installed through
  each provider's native Home Manager skills option. Add a skill here once.
  Directory sources include scripts, references, and other supporting files.
- `shared/mcps.nix`: shared `programs.mcp.servers`; Home Manager translates these
  into each provider's schema. Use absolute executable paths. Never put secrets
  directly into Nix settings; local-server environment variables can use
  `env.NAME.file` to load a secret file at runtime.

Run `rebuild` after editing. Existing agent sessions may retain loaded instructions
or skills: start a fresh session to pick up changes. In T3, refresh OpenCode's
provider status after changing its configuration. A cached OpenCode helper may
need 30 seconds idle before refreshing, or an external server may need restarting.

Skills share files, not provider capabilities. A skill requiring a particular
plugin, tool name, API key, or external executable may need a provider-specific
adapter or extra dependencies. Add dependencies explicitly; installing a skill
does not install the Python packages or commands mentioned in it.

## Provider-specific configuration

- `opencode/default.nix`: OpenCode 2 package, server settings, and plugins.
- `opencode/cli.nix`: terminal settings in writable `cli.json`, including the
  Catppuccin theme and notification-plugin selection.
- `codex.nix`: Codex settings and package selection.
- `claude-code.nix`: Claude settings and package selection.
- `t3code.nix`: nightly desktop package and provider instances. Only OpenCode,
  Codex, and Claude are enabled. CLI paths are explicit; launching from the desktop
  menu also includes Home Manager's binaries on PATH.

Neovim remains `EDITOR`. On desktop, `VISUAL` launches the configured Neovim in
Kitty through `nvim-terminal`; Android uses `nvim` directly. The Neovim desktop
entry uses the same launcher and its own icon. Start a new login session after
activation so graphical applications receive the new environment variables.

T3's editor menu is left unpatched: this nightly does not support Neovim or custom
editor commands. Upstream's terminal-editor proposal is
[PR #20912](https://github.com/pingdotgg/t3code/pull/20912), with a related Linux
default-editor proposal in [PR #18661](https://github.com/pingdotgg/t3code/pull/18661).

Codex, Claude, and T3 settings stay writable. Declared settings win at activation;
undeclared runtime settings remain. Removing a declaration does not necessarily
delete the corresponding saved setting. Review it in the application when removing
an old setting. Skills and instruction files themselves are managed by Nix.

OpenCode uses the `opencode2` package from llm-agents, exposed as the usual
`opencode` command. Both names run V2; no V1 package is installed by this module.
T3's explicit binary path points at that same V2 command.

Server settings use V2's `plugins`, `update`, `permissions`, and `mcp.servers`
fields. The pinned Home Manager module still emits V1 MCP configuration, so
`opencode/default.nix` converts the shared `programs.mcp.servers` definitions to
V2 instead. Codex and Claude retain their native Home Manager MCP integrations.
The notifier and Gemini-auth plugins both publish V2 entrypoints. The obsolete
external Codex-auth plugin stays removed because OpenCode includes that support.

The local llama.cpp provider has been removed from OpenCode. This does not change
the local model server or other tools that use it.

### V2 differences

- V2 preserves the `lsp` map but does not run language servers or supply LSP
  diagnostics. The definitions remain as a reference and the language-server
  packages remain installed for editor use. Use project lint/typecheck/compiler
  commands for OpenCode diagnostics.
- The notifier's popup/sound component runs in the interactive terminal client;
  T3 uses its own notifications. The built-in OpenCode terminal notification
  plugin is disabled to avoid duplicate alerts.
- Gemini-auth's V2 entrypoint supports login and model requests; its V1 quota
  command/tool and capacity notifications are not available in V2. Login still
  depends on the eligibility of the Google account and upstream service.
- CLI settings remain writable. Nix reapplies the declared theme and plugin
  selection at activation while preserving other V2 client preferences.

See the [upstream migration guide](https://opencode.ai/v2/docs/migrate-v1/).

## First activation and authentication

Before the first V2 launch, stop OpenCode 1 and back up the OpenCode config and
data directories (normally `~/.config/opencode` and `~/.local/share/opencode`).
V2 converts the shared database on first use; do not run V1 and V2 against it at
the same time. The validation here uses temporary state, not the live database.

Use `rebuild` to back up conflicting unmanaged configuration files before Home
Manager installs the managed files. No logins or conversation stores are managed.

Authenticate each native CLI once:

```sh
opencode auth login
codex login
claude auth login
```

OpenCode's model-provider logins are separate from T3's native Claude and Codex
instances. Open T3 with `t3code` and refresh the three providers after login.

The arXiv server uses its pinned upstream `uv.lock`, a writable source copy, and a
virtualenv under the XDG cache directory, isolated per source revision. Its first
launch downloads Python dependencies. Playwright
uses Nix's packaged MCP server and browser runtime instead of `npx @latest`.

## Updates

```sh
nix flake update t3code llm-agents
rebuild
```

`t3code` tracks ominit's hourly updated upstream nightly package. `llm-agents`
tracks numtide's regularly updated provider CLI packages. Both keep their own
nixpkgs inputs so their packaging dependencies match upstream CI; updating them
does not update the desktop's root nixpkgs. The old unused OpenCode source flake
has been replaced by the agent-package input.

The numtide binary cache is configured in `modules/core/maintenance.nix` to avoid
compiling agent packages locally. It becomes active after the first rebuild.

Update Nix-managed applications through these inputs rather than their in-app
installers. OpenCode's V2 `update` setting and Claude's CLI updater are disabled.

Skill packs in `shared/skills.nix` and the arXiv source have explicit revisions and
hashes: updating flake inputs does not advance them. To update a pack, change its
`rev` and fixed-output `hash`, then rebuild. OpenCode's remaining npm plugins still
use `@latest` and are resolved by OpenCode, independently of `flake.lock`.
