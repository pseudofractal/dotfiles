{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  sidebarExpandedWidth = config.programs.zen-browser.profiles.main.settings."zen.view.sidebar-expanded.max-width";
  sidebarExpandedWidthPx = "${toString sidebarExpandedWidth}px";
  wrappedZenTwilightPackage = let
    wrap = pkg:
      config.dotfiles.graphical.nixgl.maybeWrap {
        package = pkg;
        bin = "zen-twilight";
      };
    base = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight;
  in
    (wrap base)
    // {
      override = args: wrap (base.override args);
    };
  mozlz4a = lib.getExe pkgs.mozlz4a;
  jq = lib.getExe pkgs.jq;
  sessionsFile = "${config.xdg.configHome}/zen/main/zen-sessions.jsonlz4";
  sessionStoreFile = "${config.xdg.configHome}/zen/main/sessionstore.jsonlz4";
in {
  imports = [
    # keep-sorted start
    ./extensions.nix
    ./pinned-tabs.nix
    ./search-engines.nix
    ./spaces.nix
    ./stylus-userstyles.nix
    inputs.zen-browser.homeModules.twilight
    # keep-sorted end
  ];

  programs.zen-browser = {
    enable = true;
    package = wrappedZenTwilightPackage;
    configPath = ".config/zen";
    profiles.main = {
      id = 0;
      name = "main";
      path = "main";
      isDefault = true;
      spacesForce = false;
      pinsForce = false;
      settings = {
        "devtools.chrome.enabled" = true;
        "devtools.debugger.remote-enabled" = true;
        "webgl.disabled" = false;
        "webgl.enable-webgl2" = true;
        "webgl.force-enabled" = true;
      };
      userChrome = ''
        #navigator-toolbox[zen-sidebar-expanded="true"],
        :root[zen-sidebar-expanded="true"] #navigator-toolbox {
          --zen-sidebar-width: ${sidebarExpandedWidthPx} !important;
          --actual-zen-sidebar-width: ${sidebarExpandedWidthPx} !important;
          width: ${sidebarExpandedWidthPx} !important;
          min-width: ${sidebarExpandedWidthPx} !important;
          max-width: ${sidebarExpandedWidthPx} !important;
          inline-size: ${sidebarExpandedWidthPx} !important;
        }

        * {
          font-family: "Maple Mono" !important;
        }
      '';
    };
  };

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "application/xhtml+xml" = ["zen-twilight.desktop"];
    "text/html" = ["zen-twilight.desktop"];
    "x-scheme-handler/http" = ["zen-twilight.desktop"];
    "x-scheme-handler/https" = ["zen-twilight.desktop"];
  };

  home.activation.zenSortSpacesByPosition = lib.hm.dag.entryAfter ["zen-sessions-main"] ''
    if pgrep "zen" > /dev/null 2>&1; then
      exit 0
    fi

    sort_spaces_in_lz4() {
      lz4_file="$1"

      if [ ! -f "$lz4_file" ]; then
        return 0
      fi

      sessions_tmp="$(mktemp)"
      sessions_sorted="$(mktemp)"

      cleanup_file() {
        rm -f "$sessions_tmp" "$sessions_sorted"
      }

      ${mozlz4a} -d "$lz4_file" "$sessions_tmp" || {
        cleanup_file
        return 0
      }

      ${jq} '
        if has("spaces")
        then .spaces = ((.spaces // []) | sort_by(.position // 0))
        else .
        end
        | if has("windows")
          then .windows = ((.windows // []) | map(if (.spaces? | type) == "array" then (.spaces |= sort_by(.position // 0)) else . end))
          else .
          end
        | if has("_closedWindows")
          then ._closedWindows = ((._closedWindows // []) | map(if (.spaces? | type) == "array" then (.spaces |= sort_by(.position // 0)) else . end))
          else .
          end
      ' "$sessions_tmp" > "$sessions_sorted" || {
        cleanup_file
        return 0
      }

      ${mozlz4a} "$sessions_sorted" "$lz4_file" || {
        cleanup_file
        return 0
      }

      cleanup_file
    }

    sort_spaces_in_lz4 "${sessionsFile}"
    sort_spaces_in_lz4 "${sessionStoreFile}"
  '';

  home.activation.zenProfileDiagnostics = lib.hm.dag.entryAfter ["writeBoundary"] ''
    profile_dir="${config.xdg.configHome}/zen/main"
    compat_file="$profile_dir/compatibility.ini"
    launcher="${config.home.homeDirectory}/.nix-profile/bin/zen-twilight"

    if [ ! -d "$profile_dir" ]; then
      echo "warning: expected Zen profile directory missing: $profile_dir"
      exit 0
    fi

    if [ ! -f "$compat_file" ]; then
      echo "warning: missing Zen compatibility file: $compat_file"
      exit 0
    fi

    if [ ! -x "$launcher" ]; then
      echo "warning: expected Zen launcher not found at $launcher"
      exit 0
    fi

    resolved_launcher="$(readlink -f "$launcher" 2>/dev/null || true)"
    if [ -z "$resolved_launcher" ]; then
      echo "warning: failed to resolve Zen launcher symlink: $launcher"
      exit 0
    fi

    package_root="$(dirname "$(dirname "$resolved_launcher")")"
    expected_app_dir=""
    for candidate in "$package_root"/lib/zen-bin-*; do
      if [ -d "$candidate" ]; then
        expected_app_dir="$candidate"
        break
      fi
    done

    if [ -z "$expected_app_dir" ]; then
      echo "warning: could not locate zen app directory under $package_root/lib"
      exit 0
    fi

    last_platform_dir="$(sed -n 's/^LastPlatformDir=//p' "$compat_file" | head -n 1)"
    if [ -n "$last_platform_dir" ] && [ "$last_platform_dir" != "$expected_app_dir" ] && [ "$(basename "$last_platform_dir")" != "$(basename "$expected_app_dir")" ]; then
      sed -i "s|^LastPlatformDir=.*|LastPlatformDir=$expected_app_dir|" "$compat_file"
      echo "info: updated Zen profile LastPlatformDir to $expected_app_dir"
    fi
  '';
}
