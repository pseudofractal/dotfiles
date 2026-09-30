{
  inputs,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  niri = inputs.niri-nix.packages.${system}.niri-unstable;
  niriSession = pkgs.runCommand "niri-nix-session" {} ''
    mkdir -p "$out/bin" "$out/share/wayland-sessions"

    cat >"$out/bin/niri-nix-session" <<'EOF'
    #!${pkgs.runtimeShell}
    # niri-nix home module writes to $HOME/.config/niri/config.kdl (niri default),
    # so no NIRI_CONFIG override is needed.
    exec ${niri}/bin/niri-session "$@"
    EOF
    chmod +x "$out/bin/niri-nix-session"

    cat >"$out/share/wayland-sessions/niri-nix.desktop" <<EOF
    [Desktop Entry]
    Name=Niri (Nix)
    Comment=A scrollable-tiling Wayland compositor managed by Nix
    Exec=$out/bin/niri-nix-session
    Type=Application
    DesktopNames=niri
    EOF
  '';
in {
  imports = [inputs.nix-system-graphics.systemModules.default];

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  system-manager.allowAnyDistro = true;
  system-graphics.enable = true;

  environment = {
    systemPackages = [
      niri
      niriSession
    ];

    etc."sddm.conf.d/20-niri-nix.conf".text = ''
      [Wayland]
      SessionDir=/run/system-manager/sw/share/wayland-sessions,/usr/local/share/wayland-sessions,/usr/share/wayland-sessions
    '';
  };
}
