function __rebuild_rearm_user_timers
    if not command -q systemctl
        return 0
    end
    systemctl --user daemon-reload >/dev/null 2>&1
    systemctl --user reset-failed >/dev/null 2>&1
    set -l timer_units (systemctl --user list-units --type=timer --all --no-legend --plain 2>/dev/null | string replace -r '\s.*$' '' | string match '*.timer')
    if set -q timer_units[1]
        systemctl --user restart $timer_units
        or echo (set_color yellow)"warning: failed to re-arm user timers; run: systemctl --user restart $timer_units"(set_color normal) >&2
    end
end

function rebuild --description "Rebuild the Home Manager or System Manager configuration"
    set -l dotfiles_dir "$HOME/dotfiles"
    set -l original_dir (pwd)

    for arg in $argv
        switch $arg
            case --system
                set run_system
            case --backup
                set use_backup
            case '*'
                echo "Usage: rebuild [--system] [--backup]" >&2
                return 2
        end
    end

    if set -q run_system[1]; and set -q use_backup[1]
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
        if set -q run_system[1]
            echo "Error: --system is not available on Nix-on-Droid" >&2
            builtin cd "$original_dir"
            return 2
        else if set -q use_backup[1]
            echo "Error: --backup is not available on Nix-on-Droid" >&2
            builtin cd "$original_dir"
            return 2
        end
        nix-on-droid switch --flake .#koch --verbose
        set rebuild_status $status
    else if set -q run_system[1]
        nix run 'github:numtide/system-manager' -- switch --sudo --flake "$dotfiles_dir#arch"
        set rebuild_status $status
    else
        set switch_log (mktemp)
        if set -q use_backup[1]
            home-manager switch --flake .#pseudofractal -b "hm-bak-"(date +"%Y%m%d-%H%M%S") 2>&1 | tee $switch_log
        else
            home-manager switch --flake .#pseudofractal 2>&1 | tee $switch_log
        end
        set rebuild_status $pipestatus[1]
    end

    if test $rebuild_status -eq 0; and not set -q run_system[1]
        __rebuild_rearm_user_timers
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
