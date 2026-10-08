{
  pkgs,
  ...
}: {
  home.packages = [
    pkgs.sunshine
    pkgs.scrcpy
    pkgs.android-tools
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
