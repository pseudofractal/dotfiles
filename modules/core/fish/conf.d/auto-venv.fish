function __auto_activate_venv --on-variable PWD
    if test -f "$PWD/pyproject.toml"
        if test -d "$PWD/.venv"
            if test -f "$PWD/.venv/bin/activate.fish"
                source "$PWD/.venv/bin/activate.fish"
            end
        end
    end
end

__auto_activate_venv
