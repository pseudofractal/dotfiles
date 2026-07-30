{
  config,
  lib,
  pkgs,
  ...
}: let
  sourceUrl = "https://github.com/catppuccin/userstyles/releases/download/all-userstyles-export/import.json";
  importFile = "${config.xdg.configHome}/zen/catppuccin-userstyles-import.json";
  curl = lib.getExe pkgs.curl;
  jq = lib.getExe pkgs.jq;
  install = lib.getExe' pkgs.coreutils "install";
  refreshScript = pkgs.writeShellScriptBin "zen-refresh-catppuccin-userstyles" ''
    set -euo pipefail

    tmp_file="$(mktemp)"
    trap 'rm -f "$tmp_file"' EXIT

    ${curl} -fsSL "${sourceUrl}" -o "$tmp_file"
    ${jq} -e 'type == "array" and length > 1 and (.[0] | has("settings"))' "$tmp_file" >/dev/null
    ${jq} '
      map(
        if (
          has("usercssData")
          and (.usercssData.vars? | type == "object")
          and (.usercssData.vars.accentColor? | type == "object")
          and ((.usercssData.vars.accentColor.options? // []) | any(.value == "teal"))
        ) then
          .usercssData.vars.accentColor.default = "teal"
          | .usercssData.vars.accentColor.value = "teal"
        else
          .
        end
      )
    ' "$tmp_file" > "$tmp_file.teal"

    mv "$tmp_file.teal" "$tmp_file"
    ${install} -Dm644 "$tmp_file" "${importFile}"

    echo "Updated Stylus Catppuccin import bundle at ${importFile}"
  '';
in {
  home.packages = [refreshScript];

  home.activation.zenFetchCatppuccinUserstyles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    stamp_file="$HOME/.cache/zen-catppuccin-userstyles-stamp"
    if [ -f "$stamp_file" ]; then
      last_run=$(cat "$stamp_file")
      today=$(date +%Y%m%d)
      if [ "$last_run" = "$today" ]; then
        echo "info: already fetched today; skipping Catppuccin Stylus import bundle refresh"
        exit 0
      fi
    fi

    is_online() {
      if command -v ping >/dev/null 2>&1; then
        if ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -w 1 1.1.1.1 >/dev/null 2>&1; then
          return 0
        fi
      fi

      ${curl} -fsSIL --connect-timeout 1 --max-time 1 https://one.one.one.one >/dev/null 2>&1
    }

    if ! is_online; then
      echo "info: offline; skipping Catppuccin Stylus import bundle refresh"
      exit 0
    fi

    if ! ${lib.getExe refreshScript}; then
      echo "warning: failed to refresh Catppuccin Stylus import bundle"
      echo "warning: run zen-refresh-catppuccin-userstyles when network is available"
    else
      date +%Y%m%d > "$stamp_file"
    fi
  '';
}
