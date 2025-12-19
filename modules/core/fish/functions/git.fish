function git
    set max_scan 0
    set new_args
    for i in (seq (count $argv))
        switch $argv[$i]
            case -MAX-SIZE
                set max_scan $argv[(math $i + 1)]
                set i (math $i + 1)
            case '*'
                set new_args $new_args $argv[$i]
        end
    end
    if test $max_scan -ne 0
        echo "🔍 Scanning for files > $max_scan""MB before git add..."
        set limit (math "$max_scan * 1024 * 1024")
        set ignore_file .gitignore
        touch $ignore_file
        set ignore_dirs
        if test -s $ignore_file
            for l in (cat $ignore_file)
                if string match -q -r '/$' -- $l
                    set ignore_dirs $ignore_dirs $l
                end
            end
        end
        set files (find . -type f -not -path "./.git/*")
        set total (count $files)
        set processed 0
        set new_ignored
        for f in $files
            set cp (string replace "./" "" $f)
            set skip 0
            for d in $ignore_dirs
                if string match -q -- "$d"* $cp
                    set skip 1
                    break
                end
            end
            if test $skip -eq 1
                set processed (math "$processed + 1")
            else
                set s (stat -L -c %s "$f" 2>/dev/null)
                if test "$s" -gt "$limit"
                    if not grep -Fxq -- "$cp" $ignore_file
                        echo $cp >> $ignore_file
                        set new_ignored $new_ignored $cp
                    end
                end
                set processed (math "$processed + 1")
            end
            set barlen (math "($processed * 20)/$total")
            set bar (string repeat -n $barlen "█")
            set pad (string repeat -n (math "20 - $barlen") "░")
            printf "\r[%s%s] %d/%d" $bar $pad $processed $total
        end
        printf "\n"
        sort -u $ignore_file -o $ignore_file
        if test (count $new_ignored) -gt 0
            echo "Ignored files:"
            for p in $new_ignored
                echo $p
            end
        else
            echo "Nothing new to ignore"
        end
        echo "✅ Done scanning. Proceeding with git add..."
    end
    command git $new_args
end
