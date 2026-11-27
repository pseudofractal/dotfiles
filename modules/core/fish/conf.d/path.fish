fish_add_path --path --append --move "$HOME/.spicetify"
fish_add_path --path --prepend --move \
    "$HOME/.config/scripts" \
    "$HOME/.juliaup/bin" \
    "$HOME/.local/share/JetBrains/Toolbox/scripts" \
    "$HOME/.local/bin"
# Keep Nix/Home Manager/Julia binaries first so managed apps resolve correctly.
fish_add_path --path --prepend --move \
    "$HOME/.julia/bin" \
    "$HOME/.nix-profile/bin" \
    /nix/var/nix/profiles/default/bin
