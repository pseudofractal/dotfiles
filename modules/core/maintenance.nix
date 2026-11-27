{
  config,
  inputs,
  isAndroid,
  lib,
  pkgs,
  ...
}: let
  uvBin = "${config.home.homeDirectory}/.local/bin/uv";
  diskThresholdPercent = 80;
  trashMaxAgeDays = 30;

  uvPrune = pkgs.writeShellScript "uv-prune" ''
    if [ -x "${uvBin}" ]; then
      exec "${uvBin}" cache prune --ci
    fi
  '';

  diskCheck = pkgs.writeShellScript "disk-check" ''
    use=$(${pkgs.coreutils}/bin/df --output=pcent / | ${pkgs.coreutils}/bin/tail -n 1 | ${pkgs.coreutils}/bin/tr -dc '0-9')
    if [ -n "$use" ] && [ "$use" -ge ${toString diskThresholdPercent} ]; then
      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(${pkgs.coreutils}/bin/id -u)/bus"
      ${pkgs.libnotify}/bin/notify-send -u critical "Root disk at $use%" "Free space: trash-empty ${toString trashMaxAgeDays}, uv cache prune, sudo paccache -r"
    fi
  '';

  mkMaintenanceTimer = name: onCalendar: {
    Unit.Description = "Maintenance timer: ${name}";
    Timer = {
      OnCalendar = onCalendar;
      Persistent = true;
      RandomizedDelaySec = "15min";
    };
    Install.WantedBy = ["timers.target"];
  };
in {
  nix = {
    package = pkgs.nix;
    settings = {
      fallback = true;
      keep-derivations = true;
      keep-outputs = true;
      warn-dirty = false;
      extra-substituters = [
        "https://cache.numtide.com"
        "https://niri-nix.cachix.org"
        "https://noctalia.cachix.org"
        "https://vicinae.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
  };

  programs =
    {
      nix-your-shell = {
        enable = true;
        enableFishIntegration = true;
        nix-output-monitor.enable = !isAndroid;
      };
    }
    // lib.optionalAttrs (!isAndroid) {
      nh = {
        enable = true;
        homeFlake = "${config.home.homeDirectory}/dotfiles";
        clean = {
          enable = true;
          dates = "weekly";
          extraArgs = [
            "--keep"
            "5"
            "--keep-since"
            "7d"
            "--optimise"
          ];
        };
      };

      nix-index = {
        enable = true;
        enableFishIntegration = true;
      };

      nix-index-database.comma.enable = true;
    };

  home.packages =
    [pkgs.trash-cli]
    ++ lib.optionals (!isAndroid) (
      (with pkgs; [
        # keep-sorted start
        dix
        nix-diff
        nix-tree
        # keep-sorted end
      ])
      ++ [
        inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
      ]
    );

  systemd.user.services = {
    maintenance-uv-prune = {
      Unit.Description = "Prune uv cache";
      Service = {
        Type = "oneshot";
        ExecStart = uvPrune;
      };
    };

    maintenance-trash-empty = {
      Unit.Description = "Expire trash contents older than ${toString trashMaxAgeDays} days";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.trash-cli}/bin/trash-empty ${toString trashMaxAgeDays}";
      };
    };

    maintenance-disk-check = {
      Unit.Description = "Warn when the root disk is over ${toString diskThresholdPercent} percent full";
      Service = {
        Type = "oneshot";
        ExecStart = diskCheck;
      };
    };
  };

  systemd.user.timers = {
    maintenance-uv-prune = mkMaintenanceTimer "uv-prune" "monthly";
    maintenance-trash-empty = mkMaintenanceTimer "trash-empty" "monthly";
    maintenance-disk-check = mkMaintenanceTimer "disk-check" "daily";
  };
}
