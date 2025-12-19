function athena --description 'Read books'
    set -l vault_dir (realpath ~/vault/Books/)
    set -l current_dir (pwd)
    cd "$vault_dir"
    set -l selected_file (fzf)
    cd "$current_dir"

    if test -n "$selected_file"
        nohup sioyek --new-window "$vault_dir/$selected_file" > /dev/null 2>&1 &
    end
end
