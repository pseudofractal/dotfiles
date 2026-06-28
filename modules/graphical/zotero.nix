{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  attachmentPath = "${config.home.homeDirectory}/vault/Thesis/papers/";
  bbtCitekeyFormat = "auth.lower + year";
in {
  imports = [inputs.nur-vortriz.homeModules.zotero];

  nixpkgs.overlays = [inputs.nur-vortriz.overlays.zoteroAddons];

  programs.zotero = {
    enable = true;
    package = config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.zotero;
      bin = "zotero";
    };

    profiles.default = {
      settings = {
        "extensions.zotero.fileHandler.pdf" = "system";
        "browser.aboutConfig.showWarning" = false;
        "extensions.update.autoUpdateDefault" = false;
        "extensions.zotero.attachmentRenameTemplate" = ''{{ if {{ authors match="[^,]+,[^,]+,[^,]+" }} }}{{ authors max="1" suffix=" et al." }}{{ else }}{{ authors max="3" join=", " }}{{ endif }} - {{ year }} - {{ title }}'';
        "extensions.zotero.baseAttachmentPath" = attachmentPath;
        # "extensions.zotero.translators.better-bibtex.baseAttachmentPath" = attachmentPath;
        # "extensions.zotero.translators.better-bibtex.citekeyFormat" = bbtCitekeyFormat;
        # "extensions.zotero.translators.better-bibtex.citekeyFormatEditing" = bbtCitekeyFormat;
        # "extensions.zotero.translators.better-bibtex.path.git" = lib.getExe pkgs.git;
        # "extensions.zotmoov.dst_dir" = attachmentPath;
      };

      extensions = with pkgs.zoteroAddons; [
        zotero-scipdf
        zotmoov
      ];
    };
  };
}
