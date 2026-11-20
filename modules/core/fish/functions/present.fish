function present --description "Present a PDF with speaker notes using pdfpc"
    if test (count $argv) -eq 0
        set -l roots ~/Downloads ~/Documents ~/GitHub ~/vault
        set -l dirs
        for root in $roots
            test -d "$root"; and set -a dirs "$root"
        end

        if test (count $dirs) -eq 0
            echo "present: none of the PDF search directories exist" >&2
            return 1
        end

        set -l selection (
            command fd --type f --extension pdf --hidden --exclude .git . $dirs \
                | command fzf --prompt='PDF> ' --height=90% --reverse --border \
                    --preview='pdf-preview {}' --preview-window='right:55%:wrap'
        )

        if test -z "$selection"
            return 130
        end

        command pdfpc -w both "$selection"
        return
    end

    set -l has_windowed 0
    for arg in $argv
        if string match -qr '^(-w|--windowed)' -- $arg
            set has_windowed 1
        end
    end

    if test $has_windowed -eq 1
        command pdfpc $argv
    else
        command pdfpc -w both $argv
    end
end
