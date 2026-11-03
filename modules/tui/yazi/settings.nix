{
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) cartesianProduct;
  inherit (lib.lists) concatLists;
  username = config.home.username;

  guiOpener = run: desc: [
    {
      inherit run desc;
      orphan = true;
      for = "linux";
    }
  ];
  terminalOpener = run: desc: [
    {
      inherit run desc;
      block = true;
      for = "unix";
    }
  ];
in {
  programs.yazi.settings = {
    mgr = {
      ratio = [1 1 2];
      sort_by = "natural";
      sort_dir_first = true;
      linemode = "permissions";
      show_hidden = true;
      show_symlink = true;
    };

    preview = {
      tab_size = 2;
      cache_dir = "";
      image_filter = "catmull-rom";
      image_quality = 90;
      sixel_fraction = 15;
      ueberzug_scale = 1;
      ueberzug_offset = [0 0 0 0];
      max_height = 1000;
      max_width = 1000;
    };

    opener = {
      papyri = guiOpener "papyri %s1" "Papyri";
      sioyek = guiOpener "sioyek %s1" "Sioyek";
      okular = guiOpener "okular %s1" "Okular";
      ebook = guiOpener "ebook-viewer %s1" "Calibre viewer";
      pdfarranger = guiOpener "pdfarranger %s1" "PDF Arranger";
      imv = guiOpener "imv %s" "imv";
      gimp = guiOpener "gimp %s1" "GIMP";
      inkscape = guiOpener "inkscape %s1" "Inkscape";
      mpv = guiOpener "mpv %s" "mpv";
      vlc = guiOpener "vlc %s" "VLC";
      libreoffice = guiOpener "libreoffice %s1" "LibreOffice";
      zed = guiOpener "zeditor %s1" "Zed";
      zen = guiOpener "zen-twilight %s1" "Zen";
      siril = guiOpener "siril %s1" "Siril";
      carta = guiOpener "carta %s1" "CARTA";
      stellarium = guiOpener "stellarium %s1" "Stellarium";
      glow = terminalOpener "glow -p %s1" "Glow";
      bat = terminalOpener "bat --paging=always %s1" "bat";
    };

    plugin = {
      prepend_preloaders = [
        {
          url = "/run/user/1000/gvfs/**/*";
          run = "noop";
        }
        {
          url = "/run/media/${username}/**/*";
          run = "noop";
        }
        {
          url = "*.cb[7rz]";
          run = "comicthumb";
        }
        {
          mime = "{audio,video,image}/*";
          run = "mediainfo";
        }
        {
          mime = "application/subrip";
          run = "mediainfo";
        }
      ];

      prepend_previewers = [
        {
          url = "*.md";
          run = "enhance-piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark \"$1\"";
        }
        {
          url = "/run/user/1000/gvfs/**/*";
          run = "noop";
        }
        {
          url = "/run/media/${username}/**/*";
          run = "noop";
        }
        {
          url = "*.cb[7rz]";
          run = "comicthumb";
        }
        {
          url = "*.{csv,tsv,json,parquet}";
          run = "duckdb";
        }
        {
          mime = "{audio,video,image}/*";
          run = "mediainfo";
        }
        {
          mime = "application/subrip";
          run = "mediainfo";
        }
        {
          mime = "application/{openxmlformats-officedocument.*,oasis.opendocument.*,ms-*,msword}";
          run = "office";
        }
        {
          mime = "application/{*zip,*tar,*rar,x-bzip2,x-7z-compressed,x-xz}";
          run = "enhance-piper -- ouch list -tA \"$1\"";
        }
        {
          mime = "text/*";
          run = "code";
        }
        {
          mime = "*/xml";
          run = "code";
        }
        {
          mime = "*/javascript";
          run = "code";
        }
        {
          mime = "*/x-wine-extension-ini";
          run = "code";
        }
      ];

      prepend_spotters = [
        {
          url = "*";
          run = "file-extra-metadata";
        }
      ];
    };

    open.prepend_rules = [
      {
        url = "*.{md,markdown,mdx,typ,tex,latex,ltx}";
        use = ["edit" "papyri" "glow" "zed" "open" "reveal"];
      }
      {
        url = "*.pdf";
        use = ["open" "papyri" "sioyek" "okular" "pdfarranger" "reveal"];
      }
      {
        url = "*.{epub,mobi,azw,azw3,fb2,djvu,cbz,cbr,cbt,cb7}";
        use = ["open" "okular" "ebook" "reveal"];
      }
      {
        url = "*.{svg,svgz,ai,eps,ps,cdr,wmf,emf}";
        use = ["open" "inkscape" "gimp" "imv" "reveal"];
      }
      {
        mime = "image/vnd.djvu";
        use = ["open" "okular" "reveal"];
      }
      {
        url = "*.{xcf,psd,pcx}";
        use = ["open" "gimp" "imv" "reveal"];
      }
      {
        mime = "application/{fits,x-fits}";
        use = ["open" "siril" "carta" "reveal"];
      }
      {
        mime = "image/{fits,x-fits}";
        use = ["open" "siril" "carta" "reveal"];
      }
      {
        url = "*.{fits,fit,fts}";
        use = ["open" "siril" "carta" "reveal"];
      }
      {
        url = "*.ssc";
        use = ["open" "stellarium" "reveal"];
      }
      {
        mime = "application/x-stellarium-script";
        use = ["open" "stellarium" "reveal"];
      }
      {
        mime = "image/*";
        use = ["open" "imv" "gimp" "reveal"];
      }
      {
        mime = "{audio,video}/*";
        use = ["open" "mpv" "vlc" "reveal"];
      }
      {
        url = "*.{doc,docx,odt,rtf,xls,xlsx,ods,ppt,pptx,odp}";
        use = ["open" "libreoffice" "reveal"];
      }
      {
        url = "*.{csv,tsv}";
        use = ["edit" "libreoffice" "open" "reveal"];
      }
      {
        url = "*.{html,htm,xhtml}";
        use = ["edit" "zen" "open" "reveal"];
      }
      {
        mime = "text/*";
        use = ["edit" "zed" "bat" "open" "reveal"];
      }
      {
        mime = "inode/empty";
        use = ["edit" "open" "reveal"];
      }
      {
        mime = "application/{json,javascript,x-yaml,yaml,toml,xml}";
        use = ["open" "edit" "zed" "reveal"];
      }
      {
        mime = "application/pdf";
        use = ["open" "papyri" "sioyek" "okular" "pdfarranger" "reveal"];
      }
      {
        mime = "application/{*zip,*tar,*rar,x-bzip2,x-7z-compressed,x-xz}";
        use = ["extract" "reveal"];
      }
      {
        mime = "folder/local";
        use = ["open" "reveal"];
      }
      {
        mime = "vfs/{absent,stale}";
        use = ["download"];
      }
      {
        url = "*";
        use = ["open" "reveal"];
      }
    ];
  };
}
