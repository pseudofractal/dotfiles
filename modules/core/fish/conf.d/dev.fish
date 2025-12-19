# >>> Flutter Development >>>
set -gx PATH $HOME/Dev/flutter/bin $PATH
set -gx ANDROID_HOME "$HOME/Android/Sdk"
set -gx PATH $HOME/Android/Sdk/tools $PATH
set -gx PATH $HOME/Sdk/platform-tools $PATH
set -gx PATH $HOME/Android/Sdk $PATH
set -gx PATH $HOME/Android/Sdk/cmdline-tools/latest/bin $PATH
set -gx PATH $HOME/.pub-cache/bin $PATH
set -gx PATH /usr/lib/jvm/java-21-openjdk/bin/java $PATH
# <<< Flutter Development <<<

# >>> CUDA >>>
set -gx PATH /opt/cuda/bin $PATH
# <<< CUDA <<<

# >>> Rust >>>
source "$HOME/.cargo/env.fish"
# <<< Rust <<<

# >>> Julia >>>
set -gx PATH /home/pseudofractal/.juliaup/bin $PATH
# <<< Julia <<<

# >>> Python >>>
set -gx PATH $PYENV_ROOT/bin $PATH
# <<< Python <<<

# >>> Bun >>>
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
# <<< Bun <<<

# >>> NVM >>>
set --universal nvm_default_version latest
# <<< NVM <<<
