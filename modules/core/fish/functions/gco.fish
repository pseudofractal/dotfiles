function gco --description 'Git commit with custom date and time'
    set -l date (env TZ=Asia/Kolkata date "+%Y-%m-%d")
    set -l time (env TZ=Asia/Kolkata date "+%H:%M:%S")
    set -l msg ""
    set -l use_random 0

    for arg in $argv
        switch $arg
            case --random
                set use_random 1
            case --help -h
                echo 'Usage: gco [YYYY-MM-DD] [HH:MM:SS] ["message"] [--random]'
                return 0
            case '*'
                if string match -rq '^\d{4}-\d{2}-\d{2}$' $arg
                    set date $arg
                else if string match -rq '^\d{2}:\d{2}:\d{2}$' $arg
                    set time $arg
                else
                    set msg $msg $arg
                end
        end
    end

    if test $use_random -eq 1
        set -l hour   (random 9 22)
        set -l minute (random 0 59)
        set -l second (random 0 59)
        set time (printf "%02d:%02d:%02d" $hour $minute $second)
    end

    if test -z "$msg"
        read -P "Enter commit message: " msg
    end

    set -l datetime "$date""T""$time""+0530"
    echo "Committing with datetime: $datetime"

    env GIT_AUTHOR_DATE="$datetime" GIT_COMMITTER_DATE="$datetime" \
        git commit -m "$msg" --date="$datetime"
end

