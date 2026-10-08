function __inventory_refresh --argument-names label query_flag output_file
    if pacman $query_flag >"$output_file" 2>/dev/null
        echo (set_color --bold green)"$label package list updated: "(set_color normal)"$output_file"
    else
        echo (set_color --bold red)"Error: failed to update $label package list."(set_color normal)
        return 1
    end
end

function pacman_inventory -d "Updates the list of explicitly installed pacman packages"
    __inventory_refresh Pacman -Qqe "$HOME/.config/package_details/pacman_packages.txt"
end

function paru_inventory -d "Updates the list of explicitly installed AUR packages"
    __inventory_refresh AUR -Qmq "$HOME/.config/package_details/aur_packages.txt"
end

function inventory -d "Updates both pacman and AUR package lists"
    if pacman_inventory && paru_inventory
        echo (set_color --bold green)"All package lists updated successfully."(set_color normal)
    else
        echo (set_color --bold red)"Error: failed to update one or more package lists."(set_color normal)
        return 1
    end
end
