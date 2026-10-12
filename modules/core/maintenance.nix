{
  config,
  pkgs,
  ...
}: let
  uvBin = "${config.home.homeDirectory}/.local/bin/uv";

  uvPrune = pkgs.writeShellScript "uv-prune" ''
    if [ -x "${uvBin}" ]; then
      exec "${uvBin}" cache prune --ci
    fi
  '';

  diskCheck = pkgs.writeShellScript "disk-check" ''
    use=$(df --output=pcent / | tail -n 1 | tr -dc '0-9')
    if [ "$use" -ge 80 ]; then
      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
      ${pkgs.libnotify}/bin/notify-send -u critical "Root disk at $use%" "Free space: trash-empty 30, uv cache prune, sudo paccache -r"
    fi
  '';

  monthlyTimer = name: {
    Unit.Description = "Maintenance timer: ${name}";
    Timer = {
      OnCalendar = "monthly";
      Persistent = true;
      RandomizedDelaySec = "15min";
    };
    Install.WantedBy = ["timers.target"];
  };
in {
  nix = {
    package = pkgs.nix;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
      persistent = true;
    };
    settings = {
      auto-optimise-store = true;
      extra-substituters = [
        "https://niri-nix.cachix.org"
        "https://noctalia.cachix.org"
        "https://vicinae.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
  };

  home.packages = [pkgs.trash-cli];

  systemd.user.services = {
    maintenance-uv-prune = {
      Unit.Description = "Prune uv cache";
      Service = {
        Type = "oneshot";
        ExecStart = uvPrune;
      };
    };

    maintenance-trash-empty = {
      Unit.Description = "Expire trash contents older than 30 days";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.trash-cli}/bin/trash-empty 30";
      };
    };

    maintenance-disk-check = {
      Unit.Description = "Warn when the root disk is over 80 percent full";
      Service = {
        Type = "oneshot";
        ExecStart = diskCheck;
      };
    };
  };

  systemd.user.timers = {
    maintenance-uv-prune = monthlyTimer "uv-prune";
    maintenance-trash-empty = monthlyTimer "trash-empty";
    maintenance-disk-check = {
      Unit.Description = "Maintenance timer: disk-check";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "15min";
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
