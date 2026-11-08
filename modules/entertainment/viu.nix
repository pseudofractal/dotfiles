{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  viu = inputs.viu.packages.${pkgs.stdenv.hostPlatform.system}.default;

  icat = pkgs.writeShellScriptBin "icat" ''
    exec ${lib.getExe' pkgs.kitty "kitten"} icat "$@"
  '';

  settings = {
    general = {
      preferred_tracker = "local";
      pygment_style = "github-dark";
      preferred_spinner = "arc";
      welcome_screen = false;
      media_api = "anilist";
      provider = "allanime";
      selector = "fzf";
      auto_select_anime_result = true;
      icons = true;
      preview = "full";
      image_renderer = "icat";
      manga_viewer = "icat";
      check_for_updates = false;
      show_new_release = false;
      cache_requests = true;
      max_cache_lifetime = "03:00:00";
      normalize_titles = true;
      discord = false;
      recent = 50;
    };

    stream = {
      player = "mpv";
      quality = "1080";
      translation_type = "sub";
      server = "TOP";
      auto_next = false;
      continue_from_watch_history = true;
      preferred_watch_history = "local";
      auto_skip = false;
      episode_complete_at = 80;
      ytdlp_format = "best[height<=1080]/bestvideo[height<=1080]+bestaudio/best";
      force_forward_tracking = true;
      default_media_list_tracking = "prompt";
      sub_lang = "eng";
      use_ipc = true;
    };

    downloads = {
      downloader = "auto";
      downloads_dir = "${config.home.homeDirectory}/Videos/fastanime";
      enable_tracking = true;
      max_concurrent_downloads = 10;
      max_retry_attempts = 5;
      retry_delay = 60;
      merge_subtitles = true;
      cleanup_after_merge = true;
      server = "TOP";
      ytdlp_format = "best[height<=1080]/bestvideo[height<=1080]+bestaudio/best";
      no_check_certificate = true;
    };

    anilist = {
      per_page = 30;
      sort_by = "SEARCH_MATCH";
      media_list_sort_by = "MEDIA_POPULARITY_DESC";
      preferred_language = "english";
    };

    jikan = {
      per_page = 15;
      sort_by = "SEARCH_MATCH";
      media_list_sort_by = "MEDIA_POPULARITY_DESC";
      preferred_language = "english";
    };

    media_registry = {
      media_dir = "${config.home.homeDirectory}/Videos/fastanime/.registry";
      index_dir = "${config.xdg.configHome}/fastanime";
    };

    sessions.dir = "${config.xdg.configHome}/fastanime/.sessions";

    worker = {
      enabled = true;
      notification_check_interval = 15;
      download_check_interval = 5;
    };
  };
in {
  home.packages = [viu icat pkgs.chafa];
  home.shellAliases.fastanime = "viu";

  xdg.configFile."viu/config.toml".source =
    (pkgs.formats.toml {}).generate "viu-config.toml" settings;
}
