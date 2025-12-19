function episteme
    set -l base_dir ~/GitHub/research-papers/

    if count $argv >/dev/null
        set -l link $argv[1]

        set -l temp_file (mktemp)
        curl -L -o $temp_file "$link"

        set -l file_type (file -b --mime-type $temp_file)
        if test "$file_type" != "application/pdf"
            rm -f $temp_file
            set_color red
            echo "Error: The provided link does not point to a valid PDF file. Please provide a valid link."
            set_color normal
            return 1
        end

        read -P (set_color blue; echo -n "Enter the title of the paper: "; set_color normal) title
        read -P (set_color blue; echo -n "Enter the authors (comma-separated): "; set_color normal) authors_raw

        set -l authors (string split ", " $authors_raw)
        set -l formatted_authors ""

        if test (count $authors) -le 2
             for author in $authors
                set -l parts (string split " " $author)
                set -l last_name (string sub -l 1 $parts[-1]) # Get last part.
                set -l initials ""
                for part in $parts[1..-2] # all parts, but the last.
                  set initials "$initials" (string sub -l 1 $part)"."
                end
                set -l formatted_author "$initials$last_name"
                set -l formatted_authors "$formatted_authors$formatted_author, "

            end
        else
            set -l author1 $authors[1]
            set -l parts1 (string split " " $author1)
            set -l last_name1 (string sub -l 1 $parts1[-1])
            set -l initials1 ""
            for part in $parts1[1..-2]
                set initials1 "$initials1"(string sub -l 1 $part)"."
            end
            set -l formatted_author1 "$initials1$last_name1"

            set -l author2 $authors[2]
            set -l parts2 (string split " " $author2)
            set -l last_name2 (string sub -l 1 $parts2[-1])
            set -l initials2 ""
            for part in $parts2[1..-2]
                set initials2 "$initials2"(string sub -l 1 $part)"."
            end
            set -l formatted_author2 "$initials2$last_name2"

            set formatted_authors "$formatted_author1, $formatted_author2 et.al"
        end
        set formatted_authors (string replace -r ', $' '' $formatted_authors)

        set -l dir_name "$title [$formatted_authors]"
        set -l full_dir_path $base_dir$dir_name

        mkdir -p "$full_dir_path"

        mv $temp_file "$full_dir_path/paper.pdf"

        touch "$full_dir_path/report.typ"
        cp "$full_dir_path/paper.pdf" "$full_dir_path/report.pdf"

        set_color green
        echo "Paper downloaded and saved to: $full_dir_path/paper.pdf"
        echo "Created report.typ and report.pdf"
        set_color normal

        read -P (set_color blue; echo -n "Proceed with the rest of the operations? ([Y]/n): "; set_color normal) proceed

        if string match -iq -- "$proceed" "n"
            echo "Exiting."
            return 0
        end

        set_color blue
        echo "Opening VS Code in: $full_dir_path"
        set_color normal
        cd "$full_dir_path"
        code -n . &

        set_color blue
        echo "Opening Sioyek with paper.pdf"
        set_color normal
        sioyek --new-window paper.pdf &
        sleep 2
        set_color blue
        echo "Opening Sioyek with report.pdf"
        set_color normal
        sioyek --new-window report.pdf &

        return 0

    end

    if test (count $argv) -eq 0
       set_color blue;echo "No link. Proceeding with directory operations";set_color normal

        set -l selected_dir (find $base_dir -mindepth 1 -maxdepth 1 -type d -print0 | \
            sed "s|$base_dir||" |  \
            fzf --layout=reverse --border --no-info --preview-window hidden --no-scrollbar --bind="ctrl-c:abort" --expect=ctrl-c +i \
            | awk -F/ '{print $NF}' | string trim)

        if test -n "$selected_dir"
            set -l full_selected_path "$base_dir$selected_dir/"

            cd $full_selected_path
            echo (pwd)

            set_color blue
            echo "Opening VS Code in: $full_selected_path"
            set_color normal
            code -n . > /dev/null &
            sleep 3

            set_color blue
            echo "Opening Sioyek with paper.pdf"
            set_color normal
            sioyek --new-window "$full_selected_path/paper.pdf" > /dev/null &
            sleep 2
            set_color blue
            echo "Opening Sioyek with report.pdf"
            set_color normal
            sioyek --new-window "$full_selected_path/report.pdf" > /dev/null &


        else
            set_color red
            echo "No directory selected."
            set_color normal
        end
    end

end