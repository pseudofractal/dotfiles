function __git_ignore_large_files --argument-names max_scan_mb
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Not inside a git repository; skipping large-file scan" >&2
        return 1
    end
    echo "Scanning for files > $max_scan_mb""MB before git add..."
    set -l byte_limit (math "$max_scan_mb * 1024 * 1024")
    set -l ignore_file .gitignore
    touch $ignore_file
    set -l ignored_dirs
    if test -s $ignore_file
        for ignore_line in (cat $ignore_file)
            if string match -q -r '/$' -- $ignore_line
                set ignored_dirs $ignored_dirs $ignore_line
            end
        end
    end
    set -l candidates (find . -type f -not -path "./.git/*")
    set -l total_files (count $candidates)
    set -l done_count 0
    set -l newly_ignored
    for file_path in $candidates
        set -l repo_relative_path (string replace "./" "" $file_path)
        set -l should_skip false
        for ignored_dir in $ignored_dirs
            if string match -q -- "$ignored_dir*" $repo_relative_path
                set should_skip true
                break
            end
        end
        if test "$should_skip" = false
            set -l file_size_bytes (stat -L -c %s "$file_path" 2>/dev/null)
            if test "$file_size_bytes" -gt "$byte_limit"
                if not grep -Fxq -- "$repo_relative_path" $ignore_file
                    echo $repo_relative_path >>$ignore_file
                    set newly_ignored $newly_ignored $repo_relative_path
                end
            end
        end
        set done_count (math "$done_count + 1")
        set -l filled_width (math --scale=0 "($done_count * 20)/$total_files")
        set -l bar (string repeat -n 20 "░")
        if test $filled_width -gt 0
            set bar (string replace -r "^░{$filled_width}" (string repeat -n $filled_width "█") $bar)
        end
        printf "\r[%s] %d/%d" "$bar" $done_count $total_files
    end
    printf "\n"
    sort -u $ignore_file -o $ignore_file
    if test (count $newly_ignored) -gt 0
        echo "Ignored files:"
        for ignored_path in $newly_ignored
            echo $ignored_path
        end
    else
        echo "Nothing new to ignore"
    end
    echo "Done scanning. Proceeding with git add..."
end

function git
    set -l forwarded
    set -l max_scan_mb 0
    set -l index 1
    while test $index -le (count $argv)
        switch $argv[$index]
            case -MAX-SIZE
                if test (math $index + 1) -le (count $argv); and string match -rq '^\d+$' $argv[(math $index + 1)]
                    set max_scan_mb $argv[(math $index + 1)]
                    set index (math $index + 2)
                else
                    set forwarded $forwarded $argv[$index]
                    set index (math $index + 1)
                end
            case '*'
                set forwarded $forwarded $argv[$index]
                set index (math $index + 1)
        end
    end
    if test $max_scan_mb -ne 0
        __git_ignore_large_files $max_scan_mb
    end
    command git $forwarded
end
