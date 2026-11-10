function __nectarlink_nightly
    set -l app $argv[1]
    set -e argv[1]
    $app $argv
end

function __nectarlink_state_dir
    set -l state_base $HOME/.local/state
    if test -n "$XDG_STATE_HOME"
        set state_base $XDG_STATE_HOME
    end
    echo "$state_base/nectarlink-nightly"
end

function __nectarlink_materialize
    set -l state_dir (__nectarlink_state_dir)
    set -l app_link "$state_dir/updater"
    mkdir -p "$state_dir"
    rm -rf "$app_link"
    or return 1
    if not nix build "$argv[1]#nectarlink-nightly" --out-link "$app_link" >/dev/null
        rm -rf "$app_link"
        return 1
    end
    if not test -x "$app_link/bin/nectarlink-nightly"
        return 1
    end
    echo "$app_link/bin/nectarlink-nightly"
end

function __nectarlink_commit
    set -l app $argv[1]
    set -l dotfiles_dir $argv[2]
    set -l nightly_status $argv[3]

    if test $nightly_status -ne 0
        return 0
    end
    if not __nectarlink_nightly "$app" has-pending --repo "$dotfiles_dir"
        return 0
    end
    if not __nectarlink_nightly "$app" mark-switched --repo "$dotfiles_dir"
        echo (set_color red)"Error: could not record the NectarLink switch; rolling back"(set_color normal) >&2
        return 1
    end
    __nectarlink_nightly "$app" commit --repo "$dotfiles_dir"
    or echo (set_color yellow)"warning: could not commit the NectarLink update"(set_color normal) >&2
    return 0
end

function __nectarlink_rollback
    set -l app $argv[1]
    set -l dotfiles_dir $argv[2]
    set -l generation_before $argv[3]

    if __nectarlink_nightly "$app" has-pending --repo "$dotfiles_dir"
        __nectarlink_nightly "$app" rollback --repo "$dotfiles_dir" --clear-queued
        or echo (set_color yellow)"warning: could not roll back the NectarLink pin"(set_color normal) >&2
    end
    set -l generation_after (home-manager generations 2>/dev/null | head -n1 | string match -r '/nix/store/[^ ]+')
    if test -n "$generation_before"; and test "$generation_before" != "$generation_after"
        home-manager switch --rollback
        or echo (set_color yellow)"warning: could not roll back the Home Manager generation"(set_color normal) >&2
    end
end

function __nectarlink_mark_restart
    set -l state_dir (__nectarlink_state_dir)
    mkdir -p "$state_dir"
    if not touch "$state_dir/restart-pending"
        echo (set_color yellow)"warning: can't record a pending NectarLink restart"(set_color normal) >&2
    end
end

function __nectarlink_restart
    set -l nectarlink_before $argv[1]
    set -l force_restart $argv[2]
    set -l state_dir (__nectarlink_state_dir)
    set -l marker "$state_dir/restart-pending"
    set -l updated 0

    if test "$force_restart" = 1; or test -f "$marker"
        set updated 1
    end
    set -l nectarlink_after (readlink -f (command -v nectarlink-desktop) 2>/dev/null)
    if test "$nectarlink_before" != "$nectarlink_after"
        set updated 1
    end
    if test $updated -eq 0
        return 0
    end

    mkdir -p "$state_dir"
    touch "$marker" 2>/dev/null
    or echo (set_color yellow)"warning: can't record a pending NectarLink restart"(set_color normal) >&2

    if not command -q systemctl
        echo (set_color yellow)"warning: systemctl is unavailable; NectarLink restart is pending"(set_color normal) >&2
        return 0
    end

    set -l runtime_dir $XDG_RUNTIME_DIR
    if test -z "$runtime_dir"; and command -q id
        set runtime_dir /run/user/(id -u)
    end
    if test -z "$runtime_dir"
        echo (set_color yellow)"warning: XDG_RUNTIME_DIR is unavailable; NectarLink restart is pending"(set_color normal) >&2
        return 0
    end
    if env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user try-restart nectarlink.service >/dev/null 2>&1
        rm -f "$marker"
        or echo (set_color yellow)"warning: restarted NectarLink but could not clear the pending marker"(set_color normal) >&2
    else
        echo (set_color yellow)"warning: could not restart nectarlink.service; will retry on the next rebuild"(set_color normal) >&2
    end
end

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
    if test -z "$NECTARLINK_REBUILD_LOCKED"; and command -q flock; and not command -q nix-on-droid
        set -l state_dir (__nectarlink_state_dir)
        set -l lock_wait_seconds 60
        mkdir -p "$state_dir"
        set -lx NECTARLINK_REBUILD_LOCKED 1
        flock -w $lock_wait_seconds -E 75 "$state_dir/rebuild.lock" fish -c 'rebuild $argv' -- $argv
        set -l lock_status $status
        if test $lock_status -eq 75
            echo (set_color red)"Error: another rebuild is already running"(set_color normal) >&2
        end
        return $lock_status
    end

    set -l dotfiles_dir "$HOME/dotfiles"
    set -l original_dir (pwd)

    for arg in $argv
        switch $arg
            case --system
                set run_system 1
            case --backup
                set use_backup 1
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
    if test $status -ne 0
        echo (set_color red)"Error: can't enter $dotfiles_dir"(set_color normal) >&2
        return 1
    end

    set -l nectarlink_app ""
    set -l nectarlink_before ""

    set -l rebuild_status 0
    set -l switch_log
    set -l update_applied 0
    set -l update_unchanged 3
    set -l update_recovered 5
    set -l nightly_status $update_unchanged
    set -l force_restart 0
    set -l generation_before ""

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
        if command -q snapper
            echo "Creating pre-rebuild snapshot..."
            sudo snapper -c root create --description "pre-rebuild "(date +"%Y%m%d-%H%M%S") --cleanup-algorithm number
            or echo (set_color yellow)"warning: snapshot failed, continuing without a safety net"(set_color normal) >&2
        end
        nix run 'github:numtide/system-manager' -- switch --sudo --flake "$dotfiles_dir#arch"
        set rebuild_status $status
    else
        set -l state_dir (__nectarlink_state_dir)
        set -l app_link "$state_dir/updater"
        if test -f "$state_dir/rollback/switched"
            set force_restart 1
            __nectarlink_mark_restart
        end
        if test -d "$state_dir/rollback"
            set -l recovery_apps
            if command -q nectarlink-nightly
                set -a recovery_apps (realpath (command -v nectarlink-nightly) 2>/dev/null)
            end
            if test -x "$app_link/bin/nectarlink-nightly"
                set -a recovery_apps "$app_link/bin/nectarlink-nightly"
            end
            set -l recovered 0
            for recovery_app in $recovery_apps
                if not "$recovery_app" --help 2>/dev/null | string match -q '*recover*'
                    continue
                end
                if "$recovery_app" recover --repo "$dotfiles_dir"
                    set recovered 1
                    break
                end
            end
            if test $recovered -eq 0
                echo (set_color red)"Error: could not recover the pending NectarLink update"(set_color normal) >&2
                builtin cd "$original_dir"
                return 1
            end
        end

        set nectarlink_app (__nectarlink_materialize "$dotfiles_dir")
        if test -z "$nectarlink_app"
            echo (set_color red)"Error: can't materialize nectarlink-nightly; aborting"(set_color normal) >&2
            builtin cd "$original_dir"
            return 1
        end

        set nectarlink_before (readlink -f (command -v nectarlink-desktop) 2>/dev/null)
        set -l nightly_tag (__nectarlink_nightly "$nectarlink_app" update --repo "$dotfiles_dir")
        set nightly_status $status
        if not contains -- $nightly_status $update_applied $update_unchanged $update_recovered
            if __nectarlink_nightly "$nectarlink_app" has-pending --repo "$dotfiles_dir"
                if not __nectarlink_nightly "$nectarlink_app" rollback --repo "$dotfiles_dir"
                    echo (set_color red)"Error: NectarLink update failed and rollback failed; refusing to switch"(set_color normal) >&2
                    builtin cd "$original_dir"
                    return 1
                end
            end
            set -l current_pin (__nectarlink_nightly "$nectarlink_app" pinned --repo "$dotfiles_dir" 2>/dev/null)
            echo (set_color yellow)"warning: NectarLink nightly update failed; continuing with $current_pin"(set_color normal) >&2
        else if test $nightly_status -eq $update_applied
            set force_restart 1
            echo "NectarLink nightly: $nightly_tag"
        else if test $nightly_status -eq $update_recovered
            set force_restart 1
            echo "NectarLink: recovered a previous update"
        end

        if test $force_restart -eq 1
            __nectarlink_mark_restart
        end
        set generation_before (home-manager generations 2>/dev/null | head -n1 | string match -r '/nix/store/[^ ]+')
        set switch_log (mktemp)
        if not set -q switch_log[1]
            echo (set_color yellow)"warning: can't create a switch log; service hints will be unavailable"(set_color normal) >&2
            set switch_log /dev/null
        end
        home-manager switch --flake .#pseudofractal -b "hm-bak-"(date +"%Y%m%d-%H%M%S-%N") 2>&1 | tee $switch_log
        set rebuild_status $pipestatus[1]
    end

    if not set -q run_system[1]; and not command -q nix-on-droid
        if test $rebuild_status -eq 0
            if not __nectarlink_commit "$nectarlink_app" "$dotfiles_dir" "$nightly_status"
                set rebuild_status 1
            end
        end
        if test $rebuild_status -ne 0
            __nectarlink_rollback "$nectarlink_app" "$dotfiles_dir" "$generation_before"
        else
            __nectarlink_restart "$nectarlink_before" "$force_restart"
        end
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
        if test "$switch_log" != /dev/null
            rm -f $switch_log
        end
    end

    builtin cd "$original_dir"
    return $rebuild_status
end
