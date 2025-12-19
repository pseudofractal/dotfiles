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

    if command -q nix-on-droid
        echo (set_color green)"Detected Nix-on-Droid"(set_color normal)
        echo "Building flake output: #koch"
        nix-on-droid switch --flake .#koch  --verbose

    else
        echo (set_color blue)"Detected Standard Linux PC"(set_color normal)
        
        if not git diff --quiet
            echo (set_color yellow)"⚠️  Git tree is dirty. Using current state..."(set_color normal)
        end
        
        home-manager switch --flake .
    end

    builtin cd "$original_dir"
end
