function tablet --description "Unified Samsung tablet control over USB (mirror/input/files)"
    if test (count $argv) -eq 0
        __tablet_help
        return 0
    end
    switch $argv[1]
        case h help
            __tablet_help
        case m mirror
            __tablet_mirror $argv[2..-1]
        case i input
            __tablet_input
        case f files
            __tablet_files $argv[2..-1]
        case fa
            __tablet_files_adb
        case fk
            __tablet_files_kde
        case '*'
            __tablet_say red "unknown: tablet $argv[1] (try: tablet help)"
            return 1
    end
end

function __tablet_say
    set -l color $argv[1]
    echo (set_color $color)"$argv[2..-1]"(set_color normal)
end

function __tablet_need
    for tool in $argv
        if not command -q $tool
            __tablet_say red "$tool missing: run rebuild first"
            return 1
        end
    end
end

function __tablet_stop_service
    set -l pattern $argv[1]
    set -l label $argv[2]
    __tablet_say cyan "Stopping $label..."
    pkill -f $pattern
    for attempt in (seq 1 50)
        pgrep -f $pattern >/dev/null; or break
        sleep 0.1
    end
    if pgrep -f $pattern >/dev/null
        __tablet_say red "$label did not exit, killing forcefully"
        pkill -9 -f $pattern
        return 1
    end
    __tablet_say green "$label stopped"
    return 0
end

function __tablet_spawn
    set -l log_file $argv[1]
    mkdir -p (dirname $log_file)
    $argv[2..-1] >$log_file 2>&1 &
    disown
    set -g __tablet_last_pid $last_pid
end

function __tablet_wait_device
    __tablet_say cyan "Waiting for tablet (USB debugging must be on)..."
    adb wait-for-device 2>/dev/null
    set -l adb_state (adb get-state 2>/dev/null)
    if test "$adb_state" != device
        __tablet_say red "Tablet not authorized: accept the USB debugging prompt on its screen, then retry"
        return 1
    end
end

function __tablet_help
    echo "tablet <sub> — Samsung tablet over USB (no default; pick one)"
    echo "  m | mirror      toggle scrcpy mirror (niri fullscreen, phone icon)"
    echo "  i | input       toggle Sunshine host (drive laptop from Moonlight)"
    echo "  f | files ..    tablet filesystem (default backend: adb)"
    echo "    adb             mount over USB via MTP, cd into it"
    echo "    kdeconnect      mount over LAN via KDE Connect SFTP, cd into it"
    echo "    u | unmount     detach all tablet mounts"
    echo "    help            this files help"
    echo "  fa              shortcut: tablet files adb"
    echo "  fk              shortcut: tablet files kdeconnect"
    echo "  h | help        this help"
end

function __tablet_mirror --description "Toggle Samsung tablet mirror via scrcpy over USB"
    __tablet_need adb scrcpy; or return 1

    if pgrep -f scrcpy >/dev/null
        __tablet_stop_service scrcpy scrcpy
        return $status
    end

    __tablet_wait_device; or return 1

    set -l log_dir "$HOME/.local/state"
    __tablet_spawn "$log_dir/scrcpy.log" scrcpy --window-title="Tablet" $argv
    __tablet_say green "scrcpy detached (PID $__tablet_last_pid), logging to $log_dir/scrcpy.log"
end

function __tablet_duplicate_pairings
    set -l state_file "$HOME/.config/sunshine/sunshine_state.json"
    test -f "$state_file"; or return 0
    python3 -c "import json,hashlib,sys; d=json.load(open(sys.argv[1])); fps=[hashlib.sha256(x['cert'].encode()).hexdigest() for x in d.get('root',{}).get('named_devices',[])]; print(len(fps)-len(set(fps)))" "$state_file" 2>/dev/null
end

function __tablet_wifi_ip
    ip -4 -brief addr show wlp6s0 2>/dev/null | awk '{print $3}' | cut -d/ -f1 | string join ' '
end

function __tablet_usb_ip
    ip route get 10.211.109.2 2>/dev/null | grep -oP 'src \K[0-9.]+'
end

function __tablet_input --description "Toggle Sunshine host (tablet as laptop input via Moonlight)"
    __tablet_need sunshine; or return 1

    if pgrep -f sunshine >/dev/null
        __tablet_stop_service sunshine sunshine
        return $status
    end

    set -l log_dir "$HOME/.local/state"
    set -l duplicate_certs (__tablet_duplicate_pairings)
    if test -n "$duplicate_certs"; and test "$duplicate_certs" -gt 0
        __tablet_say yellow "$duplicate_certs duplicate client cert rows in sunshine state: future pairings will 401 until named_devices is purged (backup the file first)"
    end
    __tablet_spawn "$log_dir/sunshine.log" sunshine
    set -l server_pid $__tablet_last_pid
    set -l wifi_ip (__tablet_wifi_ip)
    set -l usb_ip (__tablet_usb_ip)
    __tablet_say red "Sunshine PID: $server_pid"
    __tablet_say yellow "Log: $log_dir/sunshine.log"
    test -n "$wifi_ip"; and __tablet_say green "Wifi Host: $wifi_ip"
    test -n "$usb_ip"; and __tablet_say green "USB Host: $usb_ip"
    __tablet_say green "Credential Page: https://localhost:47990"
end

function __tablet_files --description "Tablet filesystem via adb/MTP or KDE Connect"
    set -l backend adb
    if test (count $argv) -gt 0
        set backend $argv[1]
    end
    switch $backend
        case help
            echo "tablet files <backend> — mount tablet storage and cd into it"
            echo "  adb           USB via MTP (needs a data cable; needs fuse2 for /bin/fusermount)"
            echo "  kdeconnect    LAN via KDE Connect SFTP (needs pairing + SFTP enabled)"
            echo "  u | unmount   detach all tablet mounts"
        case adb
            __tablet_files_adb
        case kdeconnect
            __tablet_files_kde
        case u unmount
            __tablet_files_unmount
        case '*'
            __tablet_say red "unknown backend: $backend (try: tablet files help)"
            return 1
    end
end

function __tablet_files_adb --description "Mount tablet storage over USB via MTP (FUSE) and cd into it"
    __tablet_need go-mtpfs adb; or return 1

    set -l mount_point "$HOME/.local/mnt/sierpenski"
    mkdir -p "$mount_point"
    if mountpoint -q "$mount_point" 2>/dev/null
        __tablet_say green "Tablet already mounted"
        cd "$mount_point"
        return 0
    end

    set -l device_filter
    set -l samsung_count (lsusb 2>/dev/null | grep -ci samsung)
    if test "$samsung_count" -gt 1
        __tablet_wait_device; or return 1
        set -l tablet_serial (adb get-serialno 2>/dev/null)
        if test -n "$tablet_serial"; and test "$tablet_serial" != unknown
            set device_filter "-dev=$tablet_serial"
        else
            __tablet_say yellow "adb unavailable: mounting the first MTP device, may be the phone"
        end
    end

    set -l log_dir "$HOME/.local/state"
    __tablet_spawn "$log_dir/go-mtpfs.log" go-mtpfs $device_filter "$mount_point"
    for attempt in (seq 1 50)
        mountpoint -q "$mount_point" 2>/dev/null; and break
        sleep 0.1
    end
    if not mountpoint -q "$mount_point" 2>/dev/null
        __tablet_say red "MTP mount failed (see $log_dir/go-mtpfs.log; device node permissions?)"
        return 1
    end
    __tablet_say green "Tablet mounted at $mount_point (umount to detach)"
    cd "$mount_point"
end

function __tablet_kde_device_id
    for row in (kdeconnect-cli --list-devices --id-name-only 2>/dev/null)
        if string match -qi '*rpenski*' -- "$row"
            echo (string split ' ' -- $row)[1]
            return 0
        end
    end
    return 1
end

function __tablet_files_kde --description "Mount tablet storage over LAN via KDE Connect SFTP and cd into it"
    __tablet_need kdeconnect-cli; or return 1

    set -l device_id (__tablet_kde_device_id)
    if test -z "$device_id"
        __tablet_say red "Siérpenski not reachable over KDE Connect (same LAN? paired? try: kdeconnect-cli -l)"
        return 1
    end

    kdeconnect-cli --mount --device "$device_id" 2>/dev/null
    set -l sftp_path "/run/user/"(id -u)"/$device_id/storage/emulated/0"
    for attempt in (seq 1 50)
        if test -d "$sftp_path"
            cd "$sftp_path"
            __tablet_say green "Tablet storage: $sftp_path"
            return 0
        end
        sleep 0.1
    end
    __tablet_say red "KDE Connect SFTP did not appear (enable it in the tablet app)"
    return 1
end

function __tablet_files_unmount --description "Detach all tablet mounts (MTP + KDE Connect)"
    set -l failures 0

    set -l mount_point "$HOME/.local/mnt/sierpenski"
    if mountpoint -q "$mount_point" 2>/dev/null
        if umount "$mount_point" 2>/dev/null
            __tablet_say green "MTP unmounted: $mount_point"
        else
            __tablet_say red "MTP unmount failed: $mount_point"
            set failures 1
        end
        pkill -f "go-mtpfs.*sierpenski" 2>/dev/null
    end

    for mount_dir in /run/user/(id -u)/*/
        if string match -qr '/[0-9a-f]{32}/$' -- "$mount_dir"; and mountpoint -q "$mount_dir" 2>/dev/null
            if umount "$mount_dir" 2>/dev/null
                __tablet_say green "KDE Connect unmounted: $mount_dir"
            else
                __tablet_say red "KDE Connect unmount failed: $mount_dir"
                set failures 1
            end
        end
    end

    if test $failures -eq 0
        __tablet_say green "nothing left mounted"
    end
    return $failures
end
