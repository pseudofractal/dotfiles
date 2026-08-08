function git
    set max_scan_mb 0
    set forwarded_git_args
    for arg_index in (seq (count $argv))
        switch $argv[$arg_index]
            case -MAX-SIZE
                set max_scan_mb $argv[(math $arg_index + 1)]
                set arg_index (math $arg_index + 1)
            case '*'
                set forwarded_git_args $forwarded_git_args $argv[$arg_index]
        end
    end
    if test $max_scan_mb -ne 0
        echo "🔍 Scanning for files > $max_scan_mb""MB before git add..."
        set size_limit_bytes (math "$max_scan_mb * 1024 * 1024")
        set gitignore_path .gitignore
        touch $gitignore_path
        set ignored_dir_prefixes
        if test -s $gitignore_path
            for ignore_line in (cat $gitignore_path)
                if string match -q -r '/$' -- $ignore_line
                    set ignored_dir_prefixes $ignored_dir_prefixes $ignore_line
                end
            end
        end
        set repo_files (find . -type f -not -path "./.git/*")
        set total_files (count $repo_files)
        set processed_files 0
        set newly_ignored_paths
        for file_path in $repo_files
            set repo_relative_path (string replace "./" "" $file_path)
            set should_skip_file 0
            for ignored_dir in $ignored_dir_prefixes
                if string match -q -- "$ignored_dir"* $repo_relative_path
                    set should_skip_file 1
                    break
                end
            end
            if test $should_skip_file -eq 1
                set processed_files (math "$processed_files + 1")
            else
                set file_size_bytes (stat -L -c %s "$file_path" 2>/dev/null)
                if test "$file_size_bytes" -gt "$size_limit_bytes"
                    if not grep -Fxq -- "$repo_relative_path" $gitignore_path
                        echo $repo_relative_path >>$gitignore_path
                        set newly_ignored_paths $newly_ignored_paths $repo_relative_path
                    end
                end
                set processed_files (math "$processed_files + 1")
            end
            set bar_length (math "($processed_files * 20)/$total_files")
            set progress_bar (string repeat -n $bar_length "█")
            set progress_padding (string repeat -n (math "20 - $bar_length") "░")
            printf "\r[%s%s] %d/%d" $progress_bar $progress_padding $processed_files $total_files
        end
        printf "\n"
        sort -u $gitignore_path -o $gitignore_path
        if test (count $newly_ignored_paths) -gt 0
            echo "Ignored files:"
            for ignored_path in $newly_ignored_paths
                echo $ignored_path
            end
        else
            echo "Nothing new to ignore"
        end
        echo "✅ Done scanning. Proceeding with git add..."
    end
    command git $forwarded_git_args
end
