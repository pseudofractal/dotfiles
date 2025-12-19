function hermes --description "Opener of all trades"
    set -l path_to_search ~
    if test (count $argv) -gt 0
        set path_to_search $argv[1]
    end
    set -l absolute_path (realpath "$path_to_search")
    set -l selected_file (find "$absolute_path" -type f -print0 | fzf --read0)
    if test -n "$selected_file"
        set -l file_name (basename "$selected_file")
        set -l mime_type (file -b --mime-type "$selected_file")
        set -l opener (xdg-mime query default "$mime_type")
        if test -z "$opener"
            set opener "Unknown"
        end
        echo "File Name: $file_name"
        echo "MIME Type: $mime_type"
        echo "Opener: $opener"
        read -l -P "Open with $opener? (Y/n): " -n 1 -s confirm
        if test "$confirm" = "" -o "$confirm" = "y" -o "$confirm" = "Y"
            xdg-open "$selected_file"
        else
            echo "File not opened."
        end
    end
end