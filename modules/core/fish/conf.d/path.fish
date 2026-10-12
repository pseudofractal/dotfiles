set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/.local/share/JetBrains/Toolbox/scripts $PATH
set -gx PATH $PATH $HOME/.spicetify
set -gx PATH $HOME/.juliaup/bin $PATH
set -gx PATH $HOME/.config/scripts/ $PATH
# Keep Nix/Home Manager binaries first so managed apps resolve correctly.
set -gx PATH $HOME/.nix-profile/bin $PATH
set -gx PATH $HOME/.julia/bin $PATH
