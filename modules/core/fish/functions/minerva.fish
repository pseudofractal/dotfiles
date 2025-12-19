function minerva
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -g mnemosyne_git_root (git rev-parse --show-toplevel)
        if test -z "$mnemosyne_git_root"
            echo -e (set_color red)"Error: 'git rev-parse --show-toplevel' returned empty. Is this a valid Git repository?"(set_color normal)
            return 1
        end
        echo -e (set_color green)"Git repository detected at: "(set_color normal)$mnemosyne_git_root
        set -g mnemosyne_project_name (basename $mnemosyne_git_root)
        echo -e (set_color yellow)"Checking .gitignore for .contents.txt"(set_color normal)
        if not grep -q -E "^\s*\\.contents\.txt\$" "$mnemosyne_git_root/.gitignore"
            echo -e (set_color green)"Adding .contents.txt to .gitignore"(set_color normal)
            echo ".contents.txt" >> "$mnemosyne_git_root/.gitignore"
        else
            echo -e (set_color blue)".contents.txt already in .gitignore"(set_color normal)
        end
        set -g mnemosyne_contents_file "$mnemosyne_git_root/.contents.txt"
    else
        set -g mnemosyne_current_dir (pwd)
        echo -e (set_color yellow)"Not a git repository. Using current directory: "(set_color normal)$mnemosyne_current_dir
        set -g mnemosyne_project_name (basename $mnemosyne_current_dir)
        set -g mnemosyne_contents_file "$mnemosyne_current_dir/.contents.txt"
    end

    if test -z "$mnemosyne_project_name"
        echo -e (set_color red)"Error: Could not determine project name."(set_color normal)
        return 1
    end

    echo -e (set_color blue)"Project name: "(set_color normal)$mnemosyne_project_name
    echo -e (set_color yellow)"Creating .contents.txt file at: "(set_color normal)$mnemosyne_contents_file

    if not touch $mnemosyne_contents_file
        echo -e (set_color red)"Error: Could not create .contents.txt file at '$mnemosyne_contents_file'. Check permissions."(set_color normal)
        return 1
    end

    echo "$mnemosyne_project_name" > $mnemosyne_contents_file
    echo (set_color yellow)"Appending tree output..."(set_color normal)
    if not command -s tree >/dev/null 2>&1
        echo -e (set_color red)"Error: 'tree' command not found. Please install it."(set_color normal)
        return 1
    end
    tree -a -I '.git|.contents.txt' . >> $mnemosyne_contents_file
    echo -e (set_color yellow)"Appending PDF file contents..."(set_color normal)

    for mnemosyne_file in (string escape (find . -type f -name "*.pdf"))
        if test -L "$mnemosyne_file"
            echo -e (set_color magenta)"Skipping symlink: "(set_color normal)$mnemosyne_file
            continue
        end

        if test -n "$mnemosyne_git_root"
            if git check-ignore -q --no-index "$mnemosyne_file"
                echo -e (set_color magenta)"Skipping ignored file: "(set_color normal)$mnemosyne_file
                continue
            end
        end

        set -g mnemosyne_relative_path (string replace -r "^\./" "" $mnemosyne_file)
        echo -e (set_color cyan)"Processing: "(set_color normal)$mnemosyne_relative_path

        if not command -s pdftotext >/dev/null 2>&1
            echo -e (set_color red)"Error: 'pdftotext' command not found. Please install it (part of poppler-utils or xpdf)." (set_color normal)
            return 1
        end
        
        echo "____XXX_____" >> $mnemosyne_contents_file
        echo "______" >> $mnemosyne_contents_file
        echo "{FILE NAME}: $mnemosyne_relative_path" >> $mnemosyne_contents_file
        echo "_____" >> $mnemosyne_contents_file
        echo "File contents" >> $mnemosyne_contents_file
       
        pdftotext "$mnemosyne_file" - >> $mnemosyne_contents_file

        echo "__________" >> $mnemosyne_contents_file
        echo "___XXX_____" >> $mnemosyne_contents_file
    end

    echo -e (set_color green)"Finished creating .contents file for project: "(set_color normal)$mnemosyne_project_name
end