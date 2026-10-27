{pkgs, ...}: {
  home.packages = [
    # keep-sorted start
    pkgs.android-tools
    pkgs.go-mtpfs
    pkgs.scrcpy
    pkgs.sunshine
    # keep-sorted end
  ];

  xdg.dataFile."applications/tablet-mirror.desktop".text = ''
    [Desktop Entry]
    Name=Tablet Mirror
    Comment=Samsung tablet screen via scrcpy
    Exec=scrcpy
    Icon=phone
    Terminal=false
    Type=Application
    Categories=Utility;RemoteAccess;
    StartupWMClass=.scrcpy-wrapped
  '';
}
