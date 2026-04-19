{...}: let
  mkExtensionSettings = builtins.mapAttrs (_: install_url: {
    inherit install_url;
    installation_mode = "force_installed";
  });
in {
  programs.zen-browser.policies = {
    ExtensionSettings = mkExtensionSettings {
      "uBlock0@raymondhill.net" = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi";
      "zotero@chnm.gmu.edu" = "https://www.zotero.org/download/connector/dl?browser=firefox";
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
    };

    "3rdparty".Extensions."uBlock0@raymondhill.net".adminSettings = {
      userSettings = [
        ["contextMenuEnabled" true]
        ["hyperlinkAuditingDisabled" true]
        ["prefetchingDisabled" true]
        ["webrtcIPAddressHidden" true]
      ];

      selectedFilterLists = [
        "user-filters"
        "ublock-filters"
        "ublock-badware"
        "ublock-privacy"
        "ublock-unbreak"
        "easylist"
        "easyprivacy"
        "urlhaus-1"
        "adguard-generic"
        "adguard-mobile"
        "easylist-annoyances"
        "adguard-social"
        "fanboy-thirdparty_social"
        "fanboy-cookiemonster"
        "ublock-cookies-easylist"
        "adguard-cookies"
      ];
    };
  };
}
