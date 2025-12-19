function michi
    if test (count $argv) -eq 0
        echo "Usage: michi <relative-path>"
        return 1
    end

    set fullpath (realpath $argv[1])
    echo -n $fullpath | wl-copy
    echo "Copied: $fullpath"
    return 0
end
