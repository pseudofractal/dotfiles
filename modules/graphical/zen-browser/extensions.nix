{
  inputs,
  pkgs,
  ...
}: let
  firefoxAddons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in {
  programs.zen-browser.profiles.main.extensions.packages = with firefoxAddons; [
    # keep-sorted start
    bitwarden
    copy-as-markdown
    redirector
    stylus
    ublock-origin
    unpaywall
    user-agent-string-switcher
    zotero-connector
    # keep-sorted end
  ];

  programs.zen-browser.policies = {
    "3rdparty".Extensions."uBlock0@raymondhill.net".adminSettings = {
      userSettings = [
        ["contextMenuEnabled" true]
        ["hyperlinkAuditingDisabled" true]
        ["prefetchingDisabled" true]
        ["webrtcIPAddressHidden" true]
      ];

      selectedFilterLists = [
        # keep-sorted start
        "adguard-cookies"
        "adguard-generic"
        "adguard-mobile"
        "adguard-social"
        "easylist"
        "easylist-annoyances"
        "easyprivacy"
        "fanboy-cookiemonster"
        "fanboy-thirdparty_social"
        "ublock-badware"
        "ublock-cookies-easylist"
        "ublock-filters"
        "ublock-privacy"
        "ublock-unbreak"
        "urlhaus-1"
        "user-filters"
        # keep-sorted end
      ];
    };
  };
}
