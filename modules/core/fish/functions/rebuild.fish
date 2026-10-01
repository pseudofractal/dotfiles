function rebuild --description "Rebuild the Home Manager or System Manager configuration"
    set -l dotfiles_dir "$HOME/dotfiles"
    set -l original_dir (pwd)
    set -l run_system false
    set -l use_backup false

    for arg in $argv
        switch $arg
            case --system
                set run_system true
            case --backup
                set use_backup true
            case '*'
                echo "Usage: rebuild [--system] [--backup]" >&2
                return 2
        end
    end

    if test "$run_system" = true; and test "$use_backup" = true
        echo "Error: --backup only applies to Home Manager" >&2
        return 2
    end

    if not test -d "$dotfiles_dir"
        echo (set_color red)"Error: Dotfiles directory not found at $dotfiles_dir"(set_color normal)
        return 1
    end

    builtin cd "$dotfiles_dir"

    if command -q nix-on-droid
        if test "$run_system" = true
            echo "Error: --system is not available on Nix-on-Droid" >&2
            builtin cd "$original_dir"
            return 2
        else if test "$use_backup" = true
            echo "Error: --backup is not available on Nix-on-Droid" >&2
            builtin cd "$original_dir"
            return 2
        end
        nix-on-droid switch --flake .#koch --verbose
    else if test "$run_system" = true
        nix run 'github:numtide/system-manager' -- switch --sudo --flake "$dotfiles_dir#arch"
    else if test "$use_backup" = true
        home-manager switch --flake .#pseudofractal -b "hm-bak-"(date +"%Y%m%d-%H%M%S")
    else
        home-manager switch --flake .#pseudofractal
    end

    set -l rebuild_status $status
    builtin cd "$original_dir"
    return $rebuild_status
end
