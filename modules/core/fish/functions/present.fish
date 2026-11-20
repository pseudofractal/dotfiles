function present --description "Present a PDF with speaker notes using pdfpc"
    if test (count $argv) -eq 0
        echo "usage: present SLIDES.pdf [pdfpc options]" >&2
        return 64
    end

    command pdfpc -w both $argv
end
