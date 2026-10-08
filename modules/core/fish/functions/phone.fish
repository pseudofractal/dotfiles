function __phone_say --argument-names color_name message
    echo (set_color $color_name)$message(set_color normal) >&2
end

function __phone_serials
    adb devices 2>/dev/null | awk '$2 == "device" {print $1}'
end

function __phone_pick_serial
    set -l serials (__phone_serials)
    if test (count $serials) -eq 0
        __phone_say red "No authorized adb device; connect the phone and accept the RSA prompt"
        return 1
    end
    if test (count $serials) -eq 1
        echo $serials[1]
        return 0
    end
    for candidate in $serials
        set -l model (adb -s $candidate shell getprop ro.product.model 2>/dev/null | string trim)
        if not string match -q "*Tab*" $model
            echo $candidate
            return 0
        end
    end
    __phone_say yellow "Only tablets on adb; mounting the first one"
    echo $serials[1]
end

function phone --description "Mount Samsung phone via MTP and cd to it"
    __phone_say blue "phone: MTP over FUSE (go-mtpfs; gio has no backend without gvfs)"
    set -l serial (__phone_pick_serial)
    or return 1
    set -l mount_point ~/.local/mnt/phone
    mkdir -p $mount_point ~/.local/state
    if not pgrep -f "go-mtpfs.*mnt/phone" >/dev/null
        __phone_say cyan "Mounting phone..."
        go-mtpfs -dev=$serial $mount_point >~/.local/state/go-mtpfs-phone.log 2>&1 &
        sleep 2
        if not test -d "$mount_point/Internal shared storage"; and not test -d "$mount_point/Internal storage"
            __phone_say red "Failed to mount phone"
            return 1
        end
    else
        __phone_say green "Phone already mounted"
    end
    if test -d "$mount_point/Internal shared storage"
        cd "$mount_point/Internal shared storage"
    else if test -d "$mount_point/Internal storage"
        cd "$mount_point/Internal storage"
    else
        cd "$mount_point"
    end
end
