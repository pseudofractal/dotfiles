{
  config,
  isAndroid,
  lib,
  pkgs,
  ...
}: let
  jamak = pkgs.mpvScripts.buildLua {
    pname = "jamak";
    version = "unstable-2026-11-01";
    src = pkgs.fetchFromGitHub {
      owner = "arrufat";
      repo = "mpv-jamak";
      rev = "4db28ed192da75bed88295c8acf9811a78832e67";
      hash = "sha256-8IwRWOBJOK3B49nMaP137dONX2uDB4xGhxWBuHW/DUQ=";
    };
    scriptPath = ".";
    passthru.scriptName = "jamak";
  };
  anilist = pkgs.mpvScripts.buildLua {
    pname = "mpv-anilist-updater";
    version = "unstable-2026-11-01";
    src = pkgs.fetchFromGitHub {
      owner = "AzuredBlue";
      repo = "mpv-anilist-updater";
      rev = "478be4b7c52eb6631148a23cff4b492fa1ca852e";
      hash = "sha256-6Nz2j3hOadqFxDOhhAnO5ZhtXG2qHXvqDksU/M3NhGI=";
    };
    scriptPath = ".";
    passthru.scriptName = "mpv-anilist-updater";
    postPatch = ''
      substituteInPlace anilist_updater/api.py \
        --replace-fail 'TOKEN_PATH = Path(__file__).resolve().parent.parent / "anilistToken.txt"' 'TOKEN_PATH = Path("${config.sops.secrets.anilist_token.path}")'
      substituteInPlace anilist_updater/cache.py \
        --replace-fail 'CACHE_PATH = Path(__file__).resolve().parent.parent / "cache.json"' 'STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "mpv-anilist-updater"; STATE_DIR.mkdir(parents=True, exist_ok=True); CACHE_PATH = STATE_DIR / "cache.json"' \
        --replace-fail 'QUEUE_PATH = Path(__file__).resolve().parent.parent / "queue.json"' 'QUEUE_PATH = STATE_DIR / "queue.json"'
      substituteInPlace lua/backend.lua \
        --replace-fail 'local interpreters = { { "python3" } }' 'local interpreters = { { "${lib.getExe pkgs.python3}" } }'
      substituteInPlace main.lua \
        --replace-fail 'mp.add_key_binding("ctrl+a", "update_anilist"' 'mp.add_key_binding("alt+a", "update_anilist"' \
        --replace-fail 'mp.add_key_binding("ctrl+b", "launch_anilist"' 'mp.add_key_binding("alt+i", "launch_anilist"' \
        --replace-fail 'mp.add_key_binding("ctrl+d", "open_folder"' 'mp.add_key_binding("alt+o", "open_folder"'
      substituteInPlace lua/overlay.lua \
        --replace-fail 'mp.add_key_binding("c", "correct_anime_id"' 'mp.add_key_binding("alt+c", "correct_anime_id"'
    '';
  };
in {
  sops.secrets.anilist_token = lib.mkIf (!isAndroid) {};

  programs.mpv = {
    enable = true;
    config.save-position-on-quit = true;
    scripts = lib.optionals (!isAndroid) (with pkgs.mpvScripts; [
      anilist
      autosubsync-mpv
      eisa01.simplebookmark
      eisa01.simplehistory
      jamak
      mpris
      quality-menu
      smart-copy-paste-2
      sponsorblock
    ]);
    extraMakeWrapperArgs = lib.optionals (!isAndroid) [
      "--suffix"
      "PATH"
      ":"
      (lib.makeBinPath [pkgs.curl pkgs.ffmpeg pkgs.wl-clipboard])
    ];
    bindings = lib.mkIf (!isAndroid) {
      F = "script-binding quality_menu/video_formats_toggle";
      "Alt+f" = "script-binding quality_menu/audio_formats_toggle";
    };
    scriptOpts = lib.mkIf (!isAndroid) {
      autosubsync.overwrite_old_sub = false;
      jamak.auto = true;
      SmartCopyPaste_II = {
        linux_copy = "wl-copy";
        linux_paste = "wl-paste --no-newline";
      };
      sponsorblock.skip = false;
    };
    profiles.solo = lib.mkIf (!isAndroid) {
      script-opts-append = "sponsorblock-skip=yes";
    };
  };

  home.packages = lib.optionals (!isAndroid) [
    pkgs.syncplay
    pkgs.yt-dlp
  ];
}
