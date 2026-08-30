function mdview --description "Render Markdown and open it in the browser"
    argparse h/help 'theme=' -- $argv
    if test $status -ne 0
        echo "Usage: mdview [--theme latte|mocha] MARKDOWN_FILE" >&2
        return 2
    end

    if set -q _flag_help
        echo "Usage: mdview [--theme latte|mocha] MARKDOWN_FILE"
        return 0
    end

    set -l theme mocha
    if set -q _flag_theme
        set theme $_flag_theme
    end
    if test "$theme" != latte; and test "$theme" != mocha
        echo "mdview: theme must be latte or mocha: $theme" >&2
        return 2
    end

    if test (count $argv) -ne 1
        echo "Usage: mdview [--theme latte|mocha] MARKDOWN_FILE" >&2
        return 2
    end

    set -l config_home ~/.config
    if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
        set config_home "$XDG_CONFIG_HOME"
    end
    set -l css "$config_home/mdview/$theme.css"
    if not test -r "$css"
        echo "mdview: theme stylesheet not found: $css" >&2
        return 1
    end

    set -l input (realpath -- "$argv[1]")
    if test $status -ne 0; or not test -f "$input"; or not test -r "$input"
        echo "mdview: readable Markdown file not found: $argv[1]" >&2
        return 1
    end

    set -l temp_dir (mktemp -d)
    if test $status -ne 0
        echo "mdview: could not create a temporary directory" >&2
        return 1
    end
    set -l output "$temp_dir/"(basename "$input" .md)".html"

    pandoc \
        --standalone \
        --from=markdown-raw_html-raw_tex-raw_attribute+autolink_bare_uris+emoji+gfm_auto_identifiers+pipe_tables+strikeout+task_lists+tex_math_dollars+tex_math_single_backslash \
        --to=html5 \
        --highlight-style=pygments \
        --resource-path=(dirname "$input") \
        --embed-resources \
        --css="$css" \
        --mathjax="$PANDOC_MATHJAX_URL" \
        --output="$output" \
        "$input"
    if test $status -ne 0
        rm -rf "$temp_dir"
        return 1
    end

    set -l browser zen-twilight
    if set -q BROWSER; and test -n "$BROWSER"
        set browser "$BROWSER"
    end
    if not command -q "$browser"
        echo "mdview: browser command not found: $browser" >&2
        rm -rf "$temp_dir"
        return 1
    end

    nohup "$browser" "$output" >/dev/null 2>&1 &
end
