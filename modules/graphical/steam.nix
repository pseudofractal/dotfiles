{...}: {
  # Steam is installed from pacman, so nix cannot set its behavior directly.
  # Shadowing its launcher makes close actually close the window instead of
  # minimizing to tray. Valve documents STEAM_FRAME_FORCE_CLOSE=1 for this,
  # but reports on current clients are mixed; tray menu Exit always quits.
  xdg.dataFile = {
    "applications/steam.desktop".text = ''
      [Desktop Entry]
      Name=Steam
      Comment=Application for managing and playing games on Steam
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam %U
      Icon=steam
      Terminal=false
      Type=Application
      Categories=Network;FileTransfer;Game;
      MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
      Actions=Store;Community;Library;Servers;Screenshots;News;Settings;BigPicture;Friends;
      PrefersNonDefaultGPU=true
      X-KDE-RunOnDiscreteGpu=true

      [Desktop Action Store]
      Name=Store
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://store

      [Desktop Action Community]
      Name=Community
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://url/CommunityHome/

      [Desktop Action Library]
      Name=Library
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://open/games

      [Desktop Action Servers]
      Name=Servers
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://open/servers

      [Desktop Action Screenshots]
      Name=Screenshots
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://open/screenshots

      [Desktop Action News]
      Name=News
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://openurl/https://store.steampowered.com/news

      [Desktop Action Settings]
      Name=Settings
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://open/settings

      [Desktop Action BigPicture]
      Name=Big Picture
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://open/bigpicture

      [Desktop Action Friends]
      Name=Friends
      Exec=env STEAM_FRAME_FORCE_CLOSE=1 /usr/bin/steam steam://open/friends
    '';
  };
}
