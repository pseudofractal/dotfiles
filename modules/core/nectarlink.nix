{
  inputs,
  isAndroid,
  lib,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  nectarlink = inputs.nectarlink.packages.${system}.default.overrideAttrs (old: {
    # The patch sets the Wayland desktop file name before QApplication is
    # constructed. Upstream sets it afterwards, so the surface gets an empty
    # app-id and Noctalia's taskbar can't find nectarlink.desktop.
    patches = (old.patches or []) ++ [./nectarlink-app-id.patch];
    # wrapQtAppsHook rewrites RUNPATH during fixup, dropping the FFmpeg path
    # from preFixup. Add it back after the wrapper exists. FFmpeg 9 is what
    # the C++ HEVC encoder was compiled against; FFmpeg 8 is the newest ABI
    # the Rust H.264 decoder understands; OpenH264 is the H.264 encoder.
    postFixup =
      (old.postFixup or "")
      + ''
        for bin in .nectarlink-desktop-wrapped .nectarlink-wrapped; do
          if [ ! -e "$out/bin/$bin" ]; then
            echo "nectarlink: expected wrapped binary $bin is missing" >&2
            exit 1
          fi
          patchelf --add-rpath "${pkgs.lib.makeLibraryPath [pkgs.ffmpeg pkgs.ffmpeg_8 pkgs.openh264]}" "$out/bin/$bin"
        done
      '';
  });
in {
  config = lib.mkIf (!isAndroid) {
    home.packages =
      [nectarlink]
      ++ (with pkgs; [
        # Runtime helpers the Linux build looks for. FUSE comes from the host:
        # Arch's setuid /usr/bin/fusermount3 must not be shadowed by Nix's copy.
        wl-clipboard
        xclip
        xdg-utils
      ]);

    # Start in the tray at login. Disable with:
    #   systemctl --user disable --now nectarlink.service
    systemd.user.services.nectarlink = {
      Unit = {
        Description = "NectarLink phone connection";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${nectarlink}/bin/nectarlink-desktop --minimized";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
