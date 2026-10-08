function tablet --description "Toggle Samsung tablet mirror via scrcpy over USB"
    if not command -q adb; or not command -q scrcpy
        echo (set_color red)"adb/scrcpy missing: run rebuild first"(set_color normal)
        return 1
    end

    if pgrep -x scrcpy >/dev/null
        echo (set_color cyan)"Stopping scrcpy..."(set_color normal)
        pkill -x scrcpy
        for i in (seq 1 50)
            pgrep -x scrcpy >/dev/null; or break
            sleep 0.1
        end
        if pgrep -x scrcpy >/dev/null
            echo (set_color red)"scrcpy did not exit, killing forcefully"(set_color normal)
            pkill -9 -x scrcpy
            return 1
        end
        echo (set_color green)"scrcpy stopped"(set_color normal)
        return 0
    end

    echo (set_color cyan)"Waiting for tablet (USB debugging must be on)..."(set_color normal)
    adb wait-for-device 2>/dev/null
    set -l state (adb get-state 2>/dev/null)
    if test "$state" != device
        echo (set_color red)"Tablet not authorized: accept the USB debugging prompt on its screen, then retry"(set_color normal)
        return 1
    end

    set -l log_dir "$HOME/.local/state"
    mkdir -p "$log_dir"
    scrcpy --window-title="Tablet" $argv >"$log_dir/scrcpy.log" 2>&1 &
    disown
    echo (set_color green)"scrcpy detached (PID $last_pid), logging to $log_dir/scrcpy.log"(set_color normal)
end
