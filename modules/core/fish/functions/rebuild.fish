function rebuild --description "Rebuild the system configuration based on the current OS"
    set -l dotfiles_dir "$HOME/dotfiles"
    set -l original_dir (pwd)
    set -l hm_flake ".#pseudofractal"
    set -l hm_eval_attr ".#homeConfigurations.pseudofractal.config.home.activationPackage.outPath"
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

    set -l git_dirty 0
    if not git diff --no-ext-diff --quiet --exit-code 2>/dev/null
        set git_dirty 1
    else if not git diff --no-ext-diff --cached --quiet --exit-code 2>/dev/null
        set git_dirty 1
    else if git ls-files --others --exclude-standard 2>/dev/null | read -l _
        set git_dirty 1
    end

    if test -L result
        echo "Removing stale build symlink: result"
        rm result
    end

    if command -q nix-on-droid
        echo (set_color green)"Detected Nix-on-Droid"(set_color normal)
        echo "Building flake output: $droid_flake"
        if test "$git_dirty" -gt 0
            echo (set_color yellow)"⚠️  Git tree is dirty. Using current state..."(set_color normal)
            env NIX_CONFIG="warn-dirty = false" nix-on-droid switch --flake $droid_flake --verbose
        else
            nix-on-droid switch --flake $droid_flake --verbose
        end

    else
        echo (set_color blue)"Detected Standard Linux PC"(set_color normal)

        if test "$git_dirty" -gt 0
            echo (set_color yellow)"⚠️  Git tree is dirty. Using current state..."(set_color normal)
        end

        set -l backup_suffix "hm-bak-"(date +"%Y%m%d-%H%M%S")
        echo "Using Home Manager backup suffix: $backup_suffix"

        set -l hm_output
        if test "$git_dirty" -gt 0
            set hm_output (env NIX_CONFIG="warn-dirty = false" nix eval --raw --impure "$hm_eval_attr" 2>/dev/null)
        else
            set hm_output (nix eval --raw --impure "$hm_eval_attr" 2>/dev/null)
        end

        if test -n "$hm_output"
            if not nix-store --verify-path "$hm_output" >/dev/null 2>&1
                echo (set_color yellow)"⚠️  Detected corrupted Home Manager generation output: $hm_output"(set_color normal)

                set -l active_gen (readlink -f "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null)
                if test "$hm_output" = "$active_gen"
                    echo (set_color red)"Refusing to delete the currently active Home Manager generation."(set_color normal)
                    echo "Run: nix-store --verify-path $hm_output"
                    builtin cd "$original_dir"
                    return 1
                end

                echo "Deleting corrupted non-active generation output so it can be rebuilt..."
                nix-store --delete "$hm_output"
            end
        end

        if test "$git_dirty" -gt 0
            env NIX_CONFIG="warn-dirty = false" home-manager switch -b "$backup_suffix" --flake $hm_flake --impure
        else
            home-manager switch -b "$backup_suffix" --flake $hm_flake --impure
        end
    end

    builtin cd "$original_dir"
end
