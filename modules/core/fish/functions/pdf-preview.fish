function pdf-preview --description "Preview the first page of a PDF for fzf"
    set -l file $argv[1]
    if not test -f "$file"
        return 1
    end

    set -l dir (mktemp -d)
    pdftoppm -f 1 -l 1 -scale-to 700 -png -singlefile "$file" "$dir/page" >/dev/null 2>&1

    if test -f "$dir/page.png"
        chafa --size 80x35 "$dir/page.png"
    else
        pdfinfo "$file" 2>/dev/null | head -8
        echo
        pdftotext -f 1 -l 1 -layout "$file" - 2>/dev/null | head -40
    end

    rm -rf "$dir"
end
