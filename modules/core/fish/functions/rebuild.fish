function __rebuild_state_base
    if test -n "$XDG_STATE_HOME"
        echo "$XDG_STATE_HOME"
    else
        echo "$HOME/.local/state"
    end
end

function __nectarlink_state_dir
    echo (__rebuild_state_base)"/nectarlink-nightly"
end

function __rebuild_warn
    printf '%s%s%s\n' "$(set_color yellow)" "$argv" "$(set_color normal)" >&2
end

function __rebuild_err
    printf '%s%s%s\n' "$(set_color red)" "$argv" "$(set_color normal)" >&2
end

function __rebuild_usage
    echo "Usage: rebuild [OPTIONS] [-- EXTRA_ARGS...]"
    echo
    echo "Options:"
    echo "  -s, --system            Rebuild System Manager instead of Home Manager"
    echo "  -n, --dry, --dry-run    Build/preview without activating or mutating state"
    echo "  -a, --ask               Show package diff and ask before activating (Home Manager)"
    echo "      --skip-nectarlink   Skip the NectarLink nightly update check"
    echo "  -b, --backup            Accepted for compatibility (backups are always enabled)"
    echo "  -h, --help              Show this help"
    echo
    echo "Everything after -- is forwarded to the underlying rebuild command."
end

function __rebuild_resolve_binary
    set -l bin (command -v -- $argv[1] 2>/dev/null)
    if test -n "$bin"
        readlink -f -- "$bin" 2>/dev/null
    end
end

function __rebuild_hm_generation
    set -l profile (__rebuild_state_base)"/nix/profiles/home-manager"
    if test -L "$profile"
        readlink -f -- "$profile" 2>/dev/null
        return 0
    end
    home-manager generations 2>/dev/null | string match -r '.*\(current\)$' | head -n1 | string match -r '/nix/store/[^ ]+'
end

function __rebuild_sh_quote
    set -l parts
    for arg in $argv
        set -a parts "'"(string replace -a "'" "'\\''" -- "$arg")"'"
    end
    string join ' ' -- $parts
end

function __rebuild_run_logged
    set -l log_file $argv[1]
    set -e argv[1]

    if isatty stdout; and command -q script; and test "$log_file" != /dev/null
        set -l quoted (__rebuild_sh_quote $argv)
        script --quiet --return --flush --command "$quoted" "$log_file"
        return $status
    end

    $argv 2>&1 | tee "$log_file"
    return $pipestatus[1]
end

function __rebuild_should_suggest_unit
    set -l action $argv[1]
    set -l unit $argv[2]

    if string match -q '*.timer' -- "$unit"
        return 1
    end
    if not command -q systemctl
        return 0
    end
    if test "$action" = stop
        systemctl --user is-active --quiet -- "$unit" 2>/dev/null
        return $status
    end

    set -l props (systemctl --user show --property=Type,TriggeredBy -- "$unit" 2>/dev/null)
    if contains -- Type=oneshot $props
        return 1
    end
    if string match -rq '^TriggeredBy=.+' -- $props
        return 1
    end
    return 0
end

function __rebuild_print_service_hints
    set -l switch_log $argv[1]
    if test -z "$switch_log"; or test "$switch_log" = /dev/null; or not test -f "$switch_log"
        return 0
    end
    set -l raw_suggested (
        string replace -ra '\r' '' <"$switch_log" |
        string replace -ra '\e\[[0-9;?]*[ -/]*[@-~]' '' |
        string replace -ra '\e\][^\a\e]*(?:\a|\e\x5c)' '' |
        string match -r '^\s*systemctl --user (?:restart|start|stop) .*$' |
        string trim
    )
    set -l suggested
    for cmd in $raw_suggested
        set -l tokens (string split -n ' ' -- "$cmd")
        if test (count $tokens) -lt 4
            continue
        end
        set -l action $tokens[3]
        set -l kept
        for unit in $tokens[4..-1]
            if __rebuild_should_suggest_unit "$action" "$unit"
                set -a kept "$unit"
            end
        end
        if set -q kept[1]
            set -a suggested "systemctl --user $action "(string join ' ' -- $kept)
        end
    end
    if set -q suggested[1]
        echo
        printf '%sSuggested service restarts (services never restart automatically):%s\n' "$(set_color --bold yellow)" "$(set_color normal)"
        for cmd in $suggested
            printf '%s  %s%s\n' "$(set_color yellow)" "$cmd" "$(set_color normal)"
        end
    end
end

function __nectarlink_nightly
    set -l app $argv[1]
    set -e argv[1]
    $app $argv
end

function __nectarlink_materialize
    set -l state_dir (__nectarlink_state_dir)
    set -l app_link "$state_dir/updater"
    mkdir -p "$state_dir"
    command rm -rf "$app_link"
    or return 1
    if not nix build "$argv[1]#nectarlink-nightly" --out-link "$app_link" >/dev/null
        command rm -rf "$app_link"
        return 1
    end
    if not test -x "$app_link/bin/nectarlink-nightly"
        return 1
    end
    echo "$app_link/bin/nectarlink-nightly"
end

function __nectarlink_recover
    set -l dotfiles_dir $argv[1]
    set -l app_link $argv[2]

    set -l recovery_apps
    set -l installed_app (__rebuild_resolve_binary nectarlink-nightly)
    if test -n "$installed_app"
        set -a recovery_apps "$installed_app"
    end
    if test -x "$app_link/bin/nectarlink-nightly"
        set -a recovery_apps "$app_link/bin/nectarlink-nightly"
    end
    for recovery_app in $recovery_apps
        if not "$recovery_app" --help 2>/dev/null | string match -q '*recover*'
            continue
        end
        if "$recovery_app" recover --repo "$dotfiles_dir"
            return 0
        end
    end
    return 1
end

function __nectarlink_commit
    set -l app $argv[1]
    set -l dotfiles_dir $argv[2]
    set -l nightly_status $argv[3]
    set -l update_applied 0

    if test $nightly_status -ne $update_applied
        return 0
    end
    if not __nectarlink_nightly "$app" has-pending --repo "$dotfiles_dir"
        return 0
    end
    if not __nectarlink_nightly "$app" mark-switched --repo "$dotfiles_dir"
        __rebuild_err "Error: could not record the NectarLink switch; rolling back"
        return 1
    end
    __nectarlink_nightly "$app" commit --repo "$dotfiles_dir"
    or __rebuild_warn "warning: could not commit the NectarLink update"
    return 0
end

function __nectarlink_rollback
    set -l app $argv[1]
    set -l dotfiles_dir $argv[2]
    set -l generation_before $argv[3]

    if __nectarlink_nightly "$app" has-pending --repo "$dotfiles_dir"
        __nectarlink_nightly "$app" rollback --repo "$dotfiles_dir" --clear-queued
        or __rebuild_warn "warning: could not roll back the NectarLink pin"
    end
    set -l generation_after (__rebuild_hm_generation)
    if test -n "$generation_before"; and test "$generation_before" != "$generation_after"
        home-manager switch --rollback
        or __rebuild_warn "warning: could not roll back the Home Manager generation"
    end
end

function __nectarlink_mark_restart
    set -l state_dir (__nectarlink_state_dir)
    mkdir -p "$state_dir"
    if not touch "$state_dir/restart-pending"
        __rebuild_warn "warning: can't record a pending NectarLink restart"
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
    set -l nectarlink_after (__rebuild_resolve_binary nectarlink-desktop)
    if test "$nectarlink_before" != "$nectarlink_after"
        set updated 1
    end
    if test $updated -eq 0
        return 0
    end

    __nectarlink_mark_restart

    if not command -q systemctl
        __rebuild_warn "warning: systemctl is unavailable; NectarLink restart is pending"
        return 0
    end

    set -l runtime_dir $XDG_RUNTIME_DIR
    if test -z "$runtime_dir"; and command -q id
        set runtime_dir /run/user/(id -u)
    end
    if test -z "$runtime_dir"
        __rebuild_warn "warning: XDG_RUNTIME_DIR is unavailable; NectarLink restart is pending"
        return 0
    end
    if env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user try-restart nectarlink.service >/dev/null 2>&1
        command rm -f "$marker"
        or __rebuild_warn "warning: restarted NectarLink but could not clear the pending marker"
    else
        __rebuild_warn "warning: could not restart nectarlink.service; will retry on the next rebuild"
    end
end

function __rebuild_rearm_user_timers
    if not command -q systemctl
        return 0
    end
    systemctl --user daemon-reload >/dev/null 2>&1
    # Clear stale failed states before re-arming enabled user timers.
    systemctl --user reset-failed >/dev/null 2>&1
    set -l timer_units (
        systemctl --user list-unit-files --type=timer --state=enabled --full --no-pager --no-legend --plain 2>/dev/null |
        string replace -r '\s.*$' '' |
        string match '*.timer'
    )
    if set -q timer_units[1]
        systemctl --user restart $timer_units
        or __rebuild_warn "warning: failed to re-arm user timers; run: systemctl --user restart $timer_units"
    end
end

function __rebuild_droid
    set -l dotfiles_dir $argv[1]
    set -l dry_run $argv[2]
    set -l extra_args $argv[3..-1]

    if test $dry_run -eq 1
        nix-on-droid build --flake "$dotfiles_dir#koch" --verbose $extra_args
    else
        nix-on-droid switch --flake "$dotfiles_dir#koch" --verbose $extra_args
    end
end

function __rebuild_system
    set -l dotfiles_dir $argv[1]
    set -l dry_run $argv[2]
    set -l extra_args $argv[3..-1]

    set -l sm_cmd
    if command -q system-manager
        set sm_cmd system-manager
    else
        set sm_cmd nix run "$dotfiles_dir#system-manager" --
    end

    if test $dry_run -eq 1
        $sm_cmd build --flake "$dotfiles_dir#arch" $extra_args
        return $status
    end

    set -l sys_profile /nix/var/nix/profiles/system-manager-profiles/system-manager
    set -l sys_before (readlink -f -- "$sys_profile" 2>/dev/null)
    set -l pre_snapshot ""
    if command -q snapper
        echo "Creating pre-rebuild snapshot..."
        set pre_snapshot (sudo snapper -c root create -t pre --print-number --description "pre-rebuild "(date +"%Y%m%d-%H%M%S") --cleanup-algorithm number)
        if test $status -ne 0; or not string match -rq '^[0-9]+$' -- "$pre_snapshot"
            set pre_snapshot ""
            __rebuild_warn "warning: snapshot failed, continuing without a safety net"
        end
    end

    $sm_cmd switch --sudo --flake "$dotfiles_dir#arch" $extra_args
    set -l rebuild_status $status

    if test -n "$pre_snapshot"
        set -l post_desc "post-rebuild "(date +"%Y%m%d-%H%M%S")
        if test $rebuild_status -ne 0
            set post_desc "$post_desc (failed)"
        end
        sudo snapper -c root create -t post --pre-number "$pre_snapshot" --description "$post_desc" --cleanup-algorithm number >/dev/null
        or __rebuild_warn "warning: post-rebuild snapshot failed (pre-snapshot #$pre_snapshot kept)"
    end

    if test $rebuild_status -eq 0; and command -q dix
        set -l sys_after (readlink -f -- "$sys_profile" 2>/dev/null)
        if test -n "$sys_before"; and test -n "$sys_after"; and test "$sys_before" != "$sys_after"
            echo
            dix diff "$sys_before" "$sys_after"
        end
    end

    return $rebuild_status
end

function __rebuild_home
    set -l dotfiles_dir $argv[1]
    set -l dry_run $argv[2]
    set -l ask $argv[3]
    set -l skip_nectarlink $argv[4]
    set -l extra_args $argv[5..-1]

    set -l state_dir (__nectarlink_state_dir)
    set -l app_link "$state_dir/updater"
    set -l nectarlink_app ""
    set -l nectarlink_before ""
    set -l update_applied 0
    set -l update_unchanged 3
    set -l update_recovered 5
    set -l nightly_status $update_unchanged
    set -l force_restart 0

    if test $dry_run -eq 0; and test $skip_nectarlink -eq 0
        if test -f "$state_dir/rollback/switched"
            set force_restart 1
            __nectarlink_mark_restart
        end
        if test -d "$state_dir/rollback"
            if not __nectarlink_recover "$dotfiles_dir" "$app_link"
                __rebuild_err "Error: could not recover the pending NectarLink update"
                return 1
            end
        end

        set nectarlink_app (__nectarlink_materialize "$dotfiles_dir")
        if test -z "$nectarlink_app"
            __rebuild_warn "warning: can't materialize nectarlink-nightly; continuing without NectarLink update"
        else
            set nectarlink_before (__rebuild_resolve_binary nectarlink-desktop)
            set -l nightly_tag (__nectarlink_nightly "$nectarlink_app" update --repo "$dotfiles_dir")
            set nightly_status $status
            if not contains -- $nightly_status $update_applied $update_unchanged $update_recovered
                if __nectarlink_nightly "$nectarlink_app" has-pending --repo "$dotfiles_dir"
                    if not __nectarlink_nightly "$nectarlink_app" rollback --repo "$dotfiles_dir"
                        __rebuild_err "Error: NectarLink update failed and rollback failed; refusing to switch"
                        return 1
                    end
                end
                set -l current_pin (__nectarlink_nightly "$nectarlink_app" pinned --repo "$dotfiles_dir" 2>/dev/null)
                __rebuild_warn "warning: NectarLink nightly update failed; continuing with $current_pin"
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
        end
    else if test $skip_nectarlink -eq 1; and test -d "$state_dir/rollback"
        __rebuild_warn "warning: a pending NectarLink transaction exists in $state_dir/rollback"
    end

    set -l switch_cmd
    if command -q nh
        set switch_cmd nh home switch --configuration pseudofractal
        if test $dry_run -eq 1
            set -a switch_cmd --dry
        else
            set -a switch_cmd --backup-extension "hm-bak-"(date +"%Y%m%d-%H%M%S-%N")
        end
        if test $ask -eq 1
            set -a switch_cmd --ask
        end
        set -a switch_cmd "$dotfiles_dir"
        if set -q extra_args[1]
            set -a switch_cmd -- $extra_args
        end
    else
        if test $ask -eq 1
            __rebuild_warn "warning: --ask requires nh; ignoring until nh is installed"
        end
        set switch_cmd home-manager switch --flake "$dotfiles_dir#pseudofractal"
        if test $dry_run -eq 1
            set -a switch_cmd --dry-run
        else
            set -a switch_cmd -b "hm-bak-"(date +"%Y%m%d-%H%M%S-%N")
        end
        if set -q extra_args[1]
            set -a switch_cmd $extra_args
        end
    end

    if test $dry_run -eq 1
        $switch_cmd
        return $status
    end

    set -l generation_before (__rebuild_hm_generation)
    set -l switch_log (mktemp)
    if not set -q switch_log[1]; or test -z "$switch_log"
        __rebuild_warn "warning: can't create a switch log; service hints will be unavailable"
        set switch_log /dev/null
    else
        set -g __rebuild_active_log "$switch_log"
        function __rebuild_cleanup_log --on-signal INT --on-signal TERM
            if set -q __rebuild_active_log; and test -n "$__rebuild_active_log"
                command rm -f -- "$__rebuild_active_log"
                set -e __rebuild_active_log
            end
        end
    end

    __rebuild_run_logged "$switch_log" $switch_cmd
    set -l rebuild_status $status

    set -l ask_declined 0
    if test $rebuild_status -eq 0; and test $ask -eq 1; and test -n "$generation_before"
        set -l generation_after (__rebuild_hm_generation)
        if test "$generation_before" = "$generation_after"
            set ask_declined 1
        end
    end

    if test -n "$nectarlink_app"
        if test $ask_declined -eq 1; and test $nightly_status -eq $update_applied
            __nectarlink_rollback "$nectarlink_app" "$dotfiles_dir" "$generation_before"
            __rebuild_warn "Switch was not applied; rolled back the pending NectarLink pin"
        else
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
    end

    if test $rebuild_status -eq 0; and test $ask_declined -eq 0
        __rebuild_rearm_user_timers
        __rebuild_print_service_hints "$switch_log"
    end

    if test -n "$switch_log"; and test "$switch_log" != /dev/null
        command rm -f -- "$switch_log"
    end
    set -e __rebuild_active_log
    functions -e __rebuild_cleanup_log

    return $rebuild_status
end

function rebuild --description "Rebuild the Home Manager or System Manager configuration"
    set -l orig_argv $argv
    set -l own_args
    set -l extra_args
    set -l split_idx (contains -i -- -- $argv)
    if test -n "$split_idx"
        if test $split_idx -gt 1
            set own_args $argv[1..(math $split_idx - 1)]
        end
        if test $split_idx -lt (count $argv)
            set extra_args $argv[(math $split_idx + 1)..-1]
        end
    else
        set own_args $argv
    end

    argparse \
        h/help \
        s/system \
        b/backup \
        n/dry \
        dry-run \
        a/ask \
        skip-nectarlink \
        -- $own_args
    or begin
        __rebuild_usage >&2
        return 2
    end

    if set -q _flag_help[1]
        __rebuild_usage
        return 0
    end

    if set -q argv[1]
        __rebuild_err "Error: unexpected argument: $argv[1]"
        __rebuild_usage >&2
        return 2
    end

    set -l run_system 0
    set -l use_backup 0
    set -l dry_run 0
    set -l ask 0
    set -l skip_nectarlink 0
    if set -q _flag_system[1]
        set run_system 1
    end
    if set -q _flag_backup[1]
        set use_backup 1
    end
    if set -q _flag_dry[1]; or set -q _flag_dry_run[1]
        set dry_run 1
    end
    if set -q _flag_ask[1]
        set ask 1
    end
    if set -q _flag_skip_nectarlink[1]
        set skip_nectarlink 1
    end

    set -l is_droid 0
    if command -q nix-on-droid
        set is_droid 1
    end

    if test $is_droid -eq 1
        if test $run_system -eq 1
            __rebuild_err "Error: --system is not available on Nix-on-Droid"
            return 2
        else if test $use_backup -eq 1
            __rebuild_err "Error: --backup is not available on Nix-on-Droid"
            return 2
        else if test $ask -eq 1
            __rebuild_err "Error: --ask is not available on Nix-on-Droid"
            return 2
        else if test $skip_nectarlink -eq 1
            __rebuild_err "Error: --skip-nectarlink is not available on Nix-on-Droid"
            return 2
        end
    else if test $run_system -eq 1
        if test $use_backup -eq 1
            __rebuild_err "Error: --backup only applies to Home Manager"
            return 2
        else if test $ask -eq 1
            __rebuild_err "Error: --ask only applies to Home Manager"
            return 2
        else if test $skip_nectarlink -eq 1
            __rebuild_err "Error: --skip-nectarlink only applies to Home Manager"
            return 2
        end
    end

    set -l dotfiles_dir "$HOME/dotfiles"
    if not test -d "$dotfiles_dir"
        __rebuild_err "Error: Dotfiles directory not found at $dotfiles_dir"
        return 1
    end

    if test $dry_run -eq 0; and test $is_droid -eq 0; and test -z "$NECTARLINK_REBUILD_LOCKED"; and command -q flock
        set -l state_dir (__nectarlink_state_dir)
        set -l lock_wait_seconds 60
        set -l lock_timeout_status 75
        mkdir -p "$state_dir"
        set -lx NECTARLINK_REBUILD_LOCKED 1
        flock -w $lock_wait_seconds -E $lock_timeout_status "$state_dir/rebuild.lock" fish -c 'rebuild $argv' -- $orig_argv
        set -l lock_status $status
        if test $lock_status -eq $lock_timeout_status
            __rebuild_err "Error: another rebuild is already running"
        end
        return $lock_status
    end

    if test $is_droid -eq 1
        __rebuild_droid "$dotfiles_dir" $dry_run $extra_args
    else if test $run_system -eq 1
        __rebuild_system "$dotfiles_dir" $dry_run $extra_args
    else
        __rebuild_home "$dotfiles_dir" $dry_run $ask $skip_nectarlink $extra_args
    end
end
