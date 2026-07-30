function phone --description "Mount Android phone via MTP and cd to it"
    set -l usb_device (lsusb | grep -i samsung | awk '{print $2","$4}' | sed 's/://g')
    if test -z "$usb_device"
        echo (set_color red)"No Samsung phone detected"(set_color normal)
        return 1
    end

    set -l uri "mtp://[usb:$usb_device]/"
    set -l mount_point "/run/user/1000/gvfs/mtp:host=%5Busb%3A"(string replace ',' '%2C' $usb_device)"%5D"

    # Check if already mounted
    if test -d "$mount_point"
        echo (set_color green)"Phone already mounted"(set_color normal)
    else
        echo (set_color cyan)"Mounting phone..."(set_color normal)
        gio mount "$uri"
        if test $status -ne 0
            echo (set_color red)"Failed to mount phone"(set_color normal)
            return 1
        end
        sleep 1
    end

    # cd to internal storage
    if test -d "$mount_point/Internal storage"
        cd "$mount_point/Internal storage"
    else
        cd "$mount_point"
    end
end
