{
  isAndroid,
  lib,
  pkgs,
  ...
}: {
  programs.yazi.plugins = lib.mkIf (!isAndroid) {
    bunny = pkgs.yaziPlugins.bunny;
    # Upstream shadows the filename list when creating its cache on first use.
    comicthumb = pkgs.runCommand "comicthumb.yazi" {} ''
      cp -r ${pkgs.fetchFromGitHub {
        owner = "navysky12";
        repo = "comicthumb.yazi";
        rev = "fa398e831cab751223084a8dbaac21901b7c165f";
        hash = "sha256-FFPWdQxpyMyvIBJ8nR4v8EP56LDlatzxySCUwVwvGx8=";
      }} "$out"
      chmod -R u+w "$out"
      substituteInPlace "$out/main.lua" \
        --replace-fail 'local filenames, output = self.generate_list(job.file.url)' 'local output; filenames, output = self.generate_list(job.file.url)'
    '';
    custom-shell = pkgs.yaziPlugins.custom-shell;
    # Without preloaders, summary previews must not wait for a cache to appear.
    duckdb = pkgs.runCommand "duckdb.yazi" {} ''
      cp -r ${pkgs.yaziPlugins.duckdb} "$out"
      chmod -R u+w "$out"
      ${pkgs.python3}/bin/python - "$out/main.lua" <<'PY'
      import pathlib
      import sys

      path = pathlib.Path(sys.argv[1])
      source = path.read_text()
      old = """\t\twhile not is_on_list("completed", args.cache_str) do
      \t\t\tya.sleep(0.2)
      \t\tend
      \t\tclear_list("completed")
      \t\tset_opts("re_peek", true)
      \t\treturn require("duckdb"):peek(job)"""
      if source.count(old) != 1:
          raise SystemExit("duckdb preview wait block changed")
      path.write_text(source.replace(old, "\t\treturn"))
      PY
    '';
    enhance-piper = pkgs.yaziPlugins.enhance-piper;
    file-extra-metadata = pkgs.yaziPlugins.file-extra-metadata;
    git = pkgs.yaziPlugins.git;
    gvfs = pkgs.yaziPlugins.gvfs;
    jump-to-char = pkgs.yaziPlugins.jump-to-char;
    mediainfo = pkgs.yaziPlugins.mediainfo;
    mount = pkgs.yaziPlugins.mount;
    office = pkgs.yaziPlugins.office;
    ouch = pkgs.yaziPlugins.ouch;
    piper = pkgs.yaziPlugins.piper;
    restore = pkgs.yaziPlugins.restore;
    smart-enter = pkgs.yaziPlugins.smart-enter;
    smart-filter = pkgs.yaziPlugins.smart-filter;
    starship = pkgs.yaziPlugins.starship;
    toggle-pane = pkgs.yaziPlugins.toggle-pane;
    what-size = pkgs.yaziPlugins.what-size;
  };
}
