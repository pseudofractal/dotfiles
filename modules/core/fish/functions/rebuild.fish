function rebuild --description "Rebuild the Home Manager or System Manager configuration"
    set -l dotfiles_dir "$HOME/dotfiles"
    set -l original_dir (pwd)
    set -l run_system false
    set -l use_backup false

    for arg in $argv
        switch $arg
            case --system
                set run_system true
            case --backup
                set use_backup true
            case '*'
                echo "Usage: rebuild [--system] [--backup]" >&2
                return 2
        end
    end

    if test "$run_system" = true; and test "$use_backup" = true
        echo "Error: --backup only applies to Home Manager" >&2
        return 2
    end

    if not test -d "$dotfiles_dir"
        echo (set_color red)"Error: Dotfiles directory not found at $dotfiles_dir"(set_color normal)
        return 1
    end

    builtin cd "$dotfiles_dir"

    set -l rebuild_status 0
    set -l switch_log ""

    if command -q nix-on-droid
        if test "$run_system" = true
            echo "Error: --system is not available on Nix-on-Droid" >&2
            builtin cd "$original_dir"
            return 2
        else if test "$use_backup" = true
            echo "Error: --backup is not available on Nix-on-Droid" >&2
            builtin cd "$original_dir"
            return 2
        end
        nix-on-droid switch --flake .#koch --verbose
        set rebuild_status $status
    else if test "$run_system" = true
        nix run 'github:numtide/system-manager' -- switch --sudo --flake "$dotfiles_dir#arch"
        set rebuild_status $status
    else
        set switch_log (mktemp)
        if test "$use_backup" = true
            home-manager switch --flake .#pseudofractal -b "hm-bak-"(date +"%Y%m%d-%H%M%S") 2>&1 | tee $switch_log
        else
            home-manager switch --flake .#pseudofractal 2>&1 | tee $switch_log
        end
        set rebuild_status $pipestatus[1]
    end

    if test $rebuild_status -eq 0; and test "$run_system" = false; and command -q systemctl
        # Drop ghosts of retired units (e.g. mbsync.timer) so re-arming stays clean.
        systemctl --user daemon-reload >/dev/null 2>&1
        systemctl --user reset-failed >/dev/null 2>&1
        set -l timer_units (systemctl --user list-units --type=timer --all --no-legend --plain 2>/dev/null | string replace -r '\s.*$' '' | string match '*.timer')
        if set -q timer_units[1]
            systemctl --user restart $timer_units
            or echo (set_color yellow)"warning: failed to re-arm user timers; run: systemctl --user restart $timer_units"(set_color normal) >&2
        end
    end

    if test -n "$switch_log"
        set -l suggested (string match -r '^\s*systemctl --user (?:restart|start|stop) .*$' <$switch_log)
        if test $rebuild_status -eq 0; and set -q suggested[1]
            echo
            echo (set_color --bold yellow)"Suggested service restarts (services never restart automatically):"(set_color normal)
            for cmd in $suggested
                echo (set_color yellow)"  $cmd"(set_color normal)
            end
        end
        rm -f $switch_log
    end

    builtin cd "$original_dir"
    return $rebuild_status
end
