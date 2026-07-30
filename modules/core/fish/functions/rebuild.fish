function rebuild --description "Rebuild the system configuration based on the current OS"
    set -l dotfiles_dir "$HOME/dotfiles"
    set -l original_dir (pwd)
    set -l hm_flake ".#pseudofractal"
    set -l droid_flake ".#koch"

    if not test -d "$dotfiles_dir"
        echo (set_color red)"Error: Dotfiles directory not found at $dotfiles_dir"(set_color normal)
        return 1
    end

    echo (set_color cyan)"Moving to $dotfiles_dir..."(set_color normal)
    builtin cd "$dotfiles_dir"

    if contains -- "--commit" $argv
        git add -A
        set -l msg (read -P "Commit message: ")
        if test -n "$msg"
            git commit -m "$msg"
        end
    end

    if test -L result
        echo "Removing stale build symlink: result"
        rm result
    end

    if command -q nix-on-droid
        echo (set_color green)"Detected Nix-on-Droid"(set_color normal)
        echo "Building flake output: $droid_flake"
        env NIX_CONFIG="warn-dirty = false" nix-on-droid switch --flake $droid_flake --verbose

    else
        echo (set_color blue)"Detected Standard Linux PC"(set_color normal)

        set -l backup_suffix "hm-bak-"(date +"%Y%m%d-%H%M%S")
        echo "Using Home Manager backup suffix: $backup_suffix"

        env NIX_CONFIG="warn-dirty = false" home-manager switch -b "$backup_suffix" --flake $hm_flake --impure
    end

    builtin cd "$original_dir"
end
