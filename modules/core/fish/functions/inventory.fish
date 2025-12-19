function pacman_inventory -d "Updates the list of explicitly installed pacman packages"
    set -l pacman_file "$HOME/.config/package_details/pacman_packages.txt"

    if pacman -Qqe >"$pacman_file" 2>/dev/null
        set_color --bold green
        echo "Pacman package list updated: "
        set_color normal
        echo "$pacman_file"
    else
        set_color --bold red
        echo "Error: Failed to update Pacman package list."
        set_color normal
        return 1
    end
end

function paru_inventory -d "Updates the list of explicitly installed AUR packages"
    set -l paru_file "$HOME/.config/package_details/aur_packages.txt"

    if pacman -Qmq >"$paru_file" 2>/dev/null
        set_color --bold green
        echo "AUR package list updated: "
        set_color normal
        echo "$paru_file"
    else
        set_color --bold red
        echo "Error: Failed to update AUR package list."
        set_color normal
        return 1
    end
end

function inventory -d "Updates both pacman and AUR package lists"
    if pacman_inventory && paru_inventory
        set_color --bold green
        echo "All package lists updated successfully."
        set_color normal
    else
        set_color --bold red
        echo "Error: Failed to update one or more package lists."
        set_color normal
        return 1
    end
end
