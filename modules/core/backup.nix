{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotfiles.backup;

  mkRcloneCmd = name: opts: let
    expandedSource = lib.replaceStrings ["~"] [config.home.homeDirectory] opts.sourcePath;
  in
    toString (
      [
        "${pkgs.rclone}/bin/rclone"
        "sync"
        expandedSource
        "gdrive:${cfg.baseFolder}/${opts.drivePath}"
        "--config"
        config.sops.secrets.rclone_config.path
        "--fast-list"
        "--stats"
        "30s"
        "--log-level"
        "INFO"
      ]
      ++ lib.optionals opts.incremental [
        "--update"
        "--checksum"
      ]
    );
in {
  options.dotfiles.backup = {
    enable = lib.mkEnableOption "rclone backup service";

    baseFolder = lib.mkOption {
      type = lib.types.str;
      description = "Base folder on Google Drive for all backups";
      example = "Backups";
    };

    entries = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          sourcePath = lib.mkOption {
            type = lib.types.str;
            description = "Local folder/file path to back up";
          };

          drivePath = lib.mkOption {
            type = lib.types.str;
            description = "Path inside base folder on Google Drive";
          };

          incremental = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Only upload changed files (--update --checksum)";
          };

          schedule = lib.mkOption {
            type = lib.types.str;
            description = "systemd OnCalendar expression";
            example = "*-*-* 02:00:00";
          };
        };
      });
      default = {};
      description = "Backup entries";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.rclone_config = {};

    systemd.user.services =
      lib.mapAttrs' (
        name: opts:
          lib.nameValuePair "rclone-backup-${name}" {
            Unit = {
              Description = "Rclone backup: ${name}";
              After = ["network-online.target"];
              Wants = ["network-online.target"];
            };
            Service = {
              Type = "oneshot";
              ExecStart = mkRcloneCmd name opts;
            };
          }
      )
      cfg.entries;

    systemd.user.timers =
      lib.mapAttrs' (
        name: opts:
          lib.nameValuePair "rclone-backup-${name}" {
            Unit.Description = "Rclone backup timer: ${name}";
            Timer = {
              OnCalendar = opts.schedule;
              Persistent = true;
              RandomizedDelaySec = "5min";
            };
            Install.WantedBy = ["timers.target"];
          }
      )
      cfg.entries;

    programs.fish.functions =
      lib.mapAttrs' (
        name: opts:
          lib.nameValuePair "backup-${name}" {
            body = ''
              echo (set_color cyan)"Starting backup: ${name}"(set_color normal)
              ${mkRcloneCmd name opts}
              or begin
                echo (set_color red)"Backup failed: ${name}"(set_color normal)
                return 1
              end
              echo (set_color green)"Backup complete: ${name}"(set_color normal)
            '';
            description = "Manually trigger rclone backup for ${name}";
          }
      )
      cfg.entries;
  };
}
