{
  config,
  inputs,
  pkgs,
  ...
}: let
  attachmentPath = "${config.home.homeDirectory}/vault/Thesis/papers/";

  # Zotero still bundles Firefox ESR 140, which current nixpkgs marks insecure.
  zoteroPkgs = import inputs.nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
      permittedInsecurePackages = ["firefox-esr-140-bin-unwrapped-140.17.0esr"];
    };
  };
in {
  imports = [inputs.nur-vortriz.homeModules.zotero];

  nixpkgs.overlays = [inputs.nur-vortriz.overlays.zoteroAddons];

  programs.zotero = {
    enable = true;
    package = config.dotfiles.graphical.nixgl.maybeWrap {
      package = zoteroPkgs.zotero;
      bin = "zotero";
    };

    profiles.default = {
      settings = {
        "extensions.zotero.fileHandler.pdf" = "system";
        "browser.aboutConfig.showWarning" = false;
        "extensions.update.autoUpdateDefault" = false;
        "extensions.zotero.attachmentRenameTemplate" = ''{{ if {{ authors match="[^,]+,[^,]+,[^,]+" }} }}{{ authors max="1" suffix=" et al." }}{{ else }}{{ authors max="3" join=", " }}{{ endif }} - {{ year }} - {{ title }}'';
        "extensions.zotero.baseAttachmentPath" = attachmentPath;
      };

      extensions = with pkgs.zoteroAddons; [
        zotero-scipdf
        zotmoov
      ];
    };
  };
}
