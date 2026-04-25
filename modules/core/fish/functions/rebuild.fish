function rebuild --description "Rebuild the system configuration based on the current OS"
    set -l dotfiles_dir "$HOME/dotfiles"
    set -l original_dir (pwd)

    if not test -d "$dotfiles_dir"
        echo (set_color red)"Error: Dotfiles directory not found at $dotfiles_dir"(set_color normal)
        return 1
    end

    echo (set_color cyan)"Moving to $dotfiles_dir..."(set_color normal)
    builtin cd "$dotfiles_dir"

    if contains -- "--commit" $argv
        git add .
        set -l msg (read -P "Commit message: ")
        if test -n "$msg"
            git commit -m "$msg"
        end
    end

    set -l git_dirty 0
    if not git diff --no-ext-diff --quiet --exit-code 2>/dev/null
        set git_dirty 1
    else if not git diff --no-ext-diff --cached --quiet --exit-code 2>/dev/null
        set git_dirty 1
    else if git ls-files --others --exclude-standard 2>/dev/null | read -l _
        set git_dirty 1
    end

    if command -q nix-on-droid
        echo (set_color green)"Detected Nix-on-Droid"(set_color normal)
        echo "Building flake output: #koch"
        if test "$git_dirty" -gt 0
            echo (set_color yellow)"⚠️  Git tree is dirty. Using current state..."(set_color normal)
            env NIX_CONFIG="warn-dirty = false" nix-on-droid switch --flake .#koch --verbose
        else
            nix-on-droid switch --flake .#koch --verbose
        end

    else
        echo (set_color blue)"Detected Standard Linux PC"(set_color normal)

        if test "$git_dirty" -gt 0
            echo (set_color yellow)"⚠️  Git tree is dirty. Using current state..."(set_color normal)
        end

        set -l backup_suffix "hm-bak-"(date +"%Y%m%d-%H%M%S")
        echo "Using Home Manager backup suffix: $backup_suffix"
        if test "$git_dirty" -gt 0
            env NIX_CONFIG="warn-dirty = false" home-manager switch -b "$backup_suffix" --flake . --impure
        else
            home-manager switch -b "$backup_suffix" --flake . --impure
        end
    end

    builtin cd "$original_dir"
end
