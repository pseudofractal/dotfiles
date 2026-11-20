function present --description "Present a PDF with speaker notes using pdfpc"
    if test (count $argv) -eq 0
        echo "usage: present SLIDES.pdf [pdfpc options]" >&2
        return 64
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
