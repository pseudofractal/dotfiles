# Path Variable Exporters
set -gx PATH $HOME/.local/bin $PATH # .local/bin
set -gx PATH $HOME/.local/share/JetBrains/Toolbox/scripts $PATH # JetBrains Toolbox

# Spicetify
set -gx PATH $PATH /home/pseudofractal/.spicetify

# Juliaup
set -gx PATH /home/pseudofractal/.juliaup/bin $PATH

# Scripts
set -gx PATH $HOME/.config/scripts/ $PATH

# Keep Nix/Home Manager binaries first so managed apps resolve correctly.
set -gx PATH $HOME/.nix-profile/bin $PATH
