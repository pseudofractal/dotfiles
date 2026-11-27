set -gx BUN_INSTALL "$HOME/.bun"
set -l pyenv_root "$HOME/.pyenv"
if set -q PYENV_ROOT; and test -n "$PYENV_ROOT"
    set pyenv_root "$PYENV_ROOT"
end

if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end

fish_add_path --path --prepend \
    "$BUN_INSTALL/bin" \
    "$pyenv_root/bin" \
    /opt/cuda/bin

if not set -q nvm_default_version
    set --universal nvm_default_version latest
end
