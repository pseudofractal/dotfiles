if not set -q __auto_venv_markers
    set -g __auto_venv_markers pyproject.toml uv.lock requirements.txt setup.py Pipfile
end

function __auto_venv_has_marker --argument-names dir_path
    for marker_file in $__auto_venv_markers
        if test -e "$dir_path/$marker_file"
            return 0
        end
    end
    return 1
end

function __auto_venv_find_project_root_from --argument-names start_dir
    set -l current_dir "$start_dir"

    while true
        if __auto_venv_has_marker "$current_dir"
            echo "$current_dir"
            return 0
        end
        if test "$current_dir" = "/"
            return 1
        end

        set current_dir (path dirname -- "$current_dir")
    end
end

function __auto_venv_cache_add_root --argument-names root_path
    if not set -q __auto_venv_known_roots
        set -g __auto_venv_known_roots
    end

    for known_root in $__auto_venv_known_roots
        if test "$known_root" = "$root_path"
            return
        end
    end

    set -g __auto_venv_known_roots $__auto_venv_known_roots "$root_path"
end

function __auto_venv_deactivate_managed
    if functions -q deactivate
        deactivate
    end

    set -e __auto_venv_managed
    set -e __auto_venv_root
    set -e __auto_venv_path
end

function __auto_activate_venv --on-variable PWD
    set -l current_dir (pwd -P)
    set -l cache_enabled 1

    if test "$AUTO_VENV_DISABLE_CACHE" = "1"
        set cache_enabled 0
    end

    if set -q __auto_venv_managed
        if not set -q VIRTUAL_ENV
            set -e __auto_venv_managed __auto_venv_root __auto_venv_path
        else if test "$VIRTUAL_ENV" != "$__auto_venv_path"
            set -e __auto_venv_managed __auto_venv_root __auto_venv_path
        end
    end

    if set -q VIRTUAL_ENV; and not set -q __auto_venv_managed
        return
    end

    set -l project_root ""

    if test $cache_enabled -eq 1
        set -l best_cached_root ""
        set -l best_cached_len -1
        set -l valid_cached_roots

        for known_root in $__auto_venv_known_roots
            if __auto_venv_has_marker "$known_root"
                set valid_cached_roots $valid_cached_roots "$known_root"

                if test "$current_dir" = "$known_root"; or string match -q -- "$known_root/*" "$current_dir"
                    set -l known_root_len (string length -- "$known_root")
                    if test $known_root_len -gt $best_cached_len
                        set best_cached_len $known_root_len
                        set best_cached_root "$known_root"
                    end
                end
            end
        end

        set -g __auto_venv_known_roots $valid_cached_roots
        set project_root "$best_cached_root"
    end

    if test -z "$project_root"
        if set -q __auto_venv_root
            if test "$current_dir" = "$__auto_venv_root"; or string match -q -- "$__auto_venv_root/*" "$current_dir"
                set project_root "$__auto_venv_root"
            end
        end
    end

    if test -z "$project_root"
        set project_root (__auto_venv_find_project_root_from "$current_dir")
        if test -n "$project_root"; and test $cache_enabled -eq 1
            __auto_venv_cache_add_root "$project_root"
        end
    end

    set -l candidate_venv_path ""
    set -l activate_script ""

    if test -n "$project_root"
        set candidate_venv_path "$project_root/.venv"
        set activate_script "$candidate_venv_path/bin/activate.fish"
    end

    if test -f "$activate_script"
        if set -q __auto_venv_managed
            if test "$__auto_venv_root" = "$project_root"; and test "$VIRTUAL_ENV" = "$candidate_venv_path"
                return
            end

            __auto_venv_deactivate_managed
        end

        source "$activate_script"

        if set -q VIRTUAL_ENV
            set -g __auto_venv_managed 1
            set -g __auto_venv_root "$project_root"
            set -g __auto_venv_path "$VIRTUAL_ENV"
        end
        return
    end

    if set -q __auto_venv_managed
        __auto_venv_deactivate_managed
    end
end

__auto_activate_venv
