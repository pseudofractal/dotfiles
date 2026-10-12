set -gx PATH /opt/cuda/bin $PATH
source "$HOME/.cargo/env.fish"
set -gx PATH $HOME/.juliaup/bin $PATH
set -gx PATH $PYENV_ROOT/bin $PATH
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set --universal nvm_default_version latest
