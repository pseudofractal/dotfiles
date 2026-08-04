{
  isAndroid,
  lib,
  pkgs,
  ...
}: let
  kdeconnectCli = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-cli";
  kdeconnectBrowse = pkgs.writeShellScriptBin "kdeconnect-browse" ''
    set -eu

    url="''${1:-}"
    case "$url" in
      kdeconnect://*)
        device="''${url#kdeconnect://}"
        device="''${device%%/*}"
        ;;
      *)
        exit 2
        ;;
    esac

    case "$device" in
      ""|*[!0123456789abcdefABCDEF]*)
        exit 2
        ;;
    esac

    ${kdeconnectCli} --mount --device "$device"

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    storage="$runtime_dir/$device/storage/emulated/0"
    attempts=0
    while [ "$attempts" -lt 50 ]; do
      if [ -d "$storage" ]; then
        exec ${pkgs.glib}/bin/gio open "$storage"
      fi
      attempts=$((attempts + 1))
      ${pkgs.coreutils}/bin/sleep 0.1
    done

    exit 1
  '';
in {
  config = lib.mkIf (!isAndroid) {
    home.packages = with pkgs; [
      glib
      sshfs
      kdeconnectBrowse
    ];

    # KIO and the indicator use D-Bus activation even when systemd starts the daemon.
    xdg.dataFile."dbus-1/services/org.kde.kdeconnect.service".source = "${pkgs.kdePackages.kdeconnect-kde}/share/dbus-1/services/org.kde.kdeconnect.service";
    xdg.dataFile."applications/org.kde.kdeconnect-storage.desktop".text = ''
      [Desktop Entry]
      Name=KDE Connect Storage
      Type=Application
      NoDisplay=true
      Exec=${kdeconnectBrowse}/bin/kdeconnect-browse %u
      MimeType=x-scheme-handler/kdeconnect;
    '';
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications."x-scheme-handler/kdeconnect" = ["org.kde.kdeconnect-storage.desktop"];

    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}
