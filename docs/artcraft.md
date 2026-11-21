# ArtCraft MCP

The 17 ArtCraft CLIs are registered as MCP servers under `artcraft-<app>` in
[modules/programming/shared/mcps.nix](../modules/programming/shared/mcps.nix).
The shared `programs.mcp` module feeds OpenCode, Claude Code, Codex and Copilot
CLI.

## File access

Agents may **read**:

- `~/Documents`
- `~/Downloads`
- `~/GitHub`
- `~/Music`
- `~/Pictures`
- `~/Videos`
- `~/dotfiles`
- `~/vault`

Agents may **write** only under `~/ArtCraft`. Apps without automation-root
flags (`anicraft`, `cadcraft`, `filmcraft`, `gridcraft`, `lightcraft`,
`materialcraft`) run with `~/ArtCraft` as their working directory. `Craft Anything` keeps its project under `~/ArtCraft/craft-anything`.

`PdfCraft` and `WordCraft` read only `~/Documents`, because their CLIs accept
a single read root; move files there when they need them. The other apps get the
full list.

Change the roots in `artcraftReadRoots` / `artcraftWriteRoot` and rebuild.

## Trimming the set

Seventeen servers add a lot of tools to every agent. Delete entries from
`artcraftMcpArgs` to expose only the apps you use, then run `rebuild` and
restart the agent.

`LightCraft` and `PdfCraft` use `--compact` to keep their tool lists small.

## The single-gateway option

The official `ArtCraft` entry uses the `craft-ai-mcp` gateway to expose every
app through one MCP server. The launcher's Flatpak build contains it, but the
Linux release tarball, AppImage and Arch package checked here do not, so this
setup registers each app's CLI directly instead.
