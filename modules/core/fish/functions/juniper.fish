#------------------------------------------------------------------------------
# juniper — Julia project helper & LSP sysimage manager
# License: MIT | Copyright: PseudoFractal@2025
#------------------------------------------------------------------------------

function juniper --description 'Julia development and tooling helper'
    #==============================#
    # CONFIGURATION (EDITABLE)     #
    #==============================#
    # Note: Constants are SCREAMING_SNAKE_CASE. You can override any of them
    # by exporting an env var with the same name BEFORE running `juniper`.
    # Values are stored as globals so nested helpers can see them.

    if not set -q JUNIPER_VERSION;               set -g JUNIPER_VERSION               "1.1.2"; end
    if not set -q MIN_FISH_VERSION_REQUIRED;     set -g MIN_FISH_VERSION_REQUIRED     "3.4.0"; end

    # Core behavior
    if not set -q DEFAULT_JULIA_PROJECT_FLAG;    set -g DEFAULT_JULIA_PROJECT_FLAG    "--project=."; end
    if not set -q DEFAULT_JULIA_THREADS;         set -g DEFAULT_JULIA_THREADS         "auto"; end
    if not set -q DEFAULT_COLOR_OUTPUT;          set -g DEFAULT_COLOR_OUTPUT          "1"; end

    # Paths / artifacts
    if not set -q OUTPUT_ARTIFACTS_DIR;          set -g OUTPUT_ARTIFACTS_DIR          "artifacts"; end
    if not set -q DOCS_MAKE_PATH;                set -g DOCS_MAKE_PATH                "docs/make.jl"; end
    if not set -q CLEAN_PATHS;                   set -g CLEAN_PATHS                   "docs/build docs/site docs/dev .documenter .docs_cache coverage.lcov lcov.info *.cov *.jl.cov $OUTPUT_ARTIFACTS_DIR build *.png"; end

    # LanguageServer sysimage rebuild
    if not set -q LSP_SYSIMAGE_PATH;             set -g LSP_SYSIMAGE_PATH             "$HOME/.config/nvim/julia/julials_system_image.so"; end
    if not set -q LSP_PROJECT_ENV;               set -g LSP_PROJECT_ENV               "@julia-lsp"; end
    if not set -q LSP_REBUILD_LOG_PATH;          set -g LSP_REBUILD_LOG_PATH          "$HOME/.config/nvim/julia/system_image_rebuild.log"; end
    if not set -q NETWORK_CHECK_HOST;            set -g NETWORK_CHECK_HOST            "1.1.1.1"; end
    if not set -q SYSTEM_BUSY_LOAD_THRESHOLD;    set -g SYSTEM_BUSY_LOAD_THRESHOLD    "2.0"; end

    # Formatting / linting
    if not set -q DEFAULT_JULIA_FORMATTER_PKG;   set -g DEFAULT_JULIA_FORMATTER_PKG   "JuliaFormatter"; end
    if not set -q DEFAULT_JULIA_LINTER_PKG;      set -g DEFAULT_JULIA_LINTER_PKG      "Aqua"; end
    if not set -q ENABLE_FISH_FORMAT_HELPER;     set -g ENABLE_FISH_FORMAT_HELPER     "1"; end

    # UX toggles
    if not set -q DEFAULT_AUTO_OPEN_OUTPUTS;     set -g DEFAULT_AUTO_OPEN_OUTPUTS     "0"; end
    if not set -q DEFAULT_FAST_TEST_FLAG;        set -g DEFAULT_FAST_TEST_FLAG        "0"; end

    #==============================#
    # Color + misc helpers         #
    #==============================#
    function __juniper_echo_info
        if test "$DEFAULT_COLOR_OUTPUT" = "1"; set_color blue; echo -n "[INFO] "; set_color normal; end; echo $argv
    end
    function __juniper_echo_ok
        if test "$DEFAULT_COLOR_OUTPUT" = "1"; set_color green; echo -n "[OK] "; set_color normal; end; echo $argv
    end
    function __juniper_echo_error
        if test "$DEFAULT_COLOR_OUTPUT" = "1"; set_color red; echo -n "[ERROR] "; set_color normal; end; echo $argv >&2
    end
    function __juniper_usage
        printf "juniper %s — Julia dev helper + LSP sysimage\n\n" $JUNIPER_VERSION
        echo "Usage: juniper [global-flags] <subcommand> [args]"
        echo
        echo "Global flags:"
        echo "  -h, --help              Show help"
        echo "  -v, --verbose           Verbose logging"
        echo "  -n, --dry-run           Print commands without executing"
        echo "  -t, --threads N         Julia threads (default: $DEFAULT_JULIA_THREADS)"
        echo "  -s, --seed N            Test seed (ENV[JULIA_TEST_SEED])"
        echo "  -c, --coverage          Enable coverage for test/ci"
        echo "  -q, --quick             Export QUICK=1 for fast paths"
        echo "  -o, --open              Try to open generated outputs"
        echo
        echo "Subcommands:"
        echo "  init | build | test | repl | doctest | docs"
        echo "  status | update | gc | precompile | clean"
        echo "  format [julia|fish] | lint | ci | coverage"
        echo "  pluto | rebuild_lsp_system_image"
    end
    function __juniper_log
        if set -q __juniper_flag_verbose; printf "[%s] %s\n" (date "+%H:%M:%S") "$argv"; end
    end
    function __juniper_mktemp_script
        set -l f (mktemp -t juniper_XXXXXXXX.jl); or begin; __juniper_echo_error "mktemp failed"; return 1; end
        echo $f
    end
    function __juniper_version_ge
        set -l have (string replace -r '^[^0-9]*' '' -- $argv[1] | string replace -r '[^0-9.]' '')
        set -l need (string replace -r '^[^0-9]*' '' -- $argv[2] | string replace -r '[^0-9.]' '')
        set -l ha (string split . -- $have); set -l ne (string split . -- $need)
        for i in 1 2 3
            set -l a 0; set -l b 0
            if test (count $ha) -ge $i; set a $ha[$i]; end
            if test (count $ne) -ge $i; set b $ne[$i]; end
            if test (math $a) -gt (math $b); return 0; else if test (math $a) -lt (math $b); return 1; end
        end
        return 0
    end
    function __juniper_build_julia_command_with_threads
        set -g __JULIA_CMD julia --color=yes $DEFAULT_JULIA_PROJECT_FLAG
        if test -n "$__juniper_flag_threads"
            set -a __JULIA_CMD --threads=$__juniper_flag_threads
        else if test -n "$DEFAULT_JULIA_THREADS"
            set -a __JULIA_CMD --threads=$DEFAULT_JULIA_THREADS
        end
    end
    function __juniper_run_julia_code
        set -l tmp (__juniper_mktemp_script); or return 1
        printf "%s\n" $argv > $tmp
        __juniper_build_julia_command_with_threads
        if set -q __juniper_flag_dry_run
            echo $__JULIA_CMD $tmp
        else
            __juniper_log "julia script: $tmp"
            $__JULIA_CMD $tmp
            set -l ec $status
            rm -f $tmp
            return $ec
        end
    end

    function __juniper_quick_network_up
        ping -c 1 -W 1 $NETWORK_CHECK_HOST >/dev/null 2>&1; or ping -c 1 -w 1 $NETWORK_CHECK_HOST >/dev/null 2>&1
    end
    function __juniper_current_loadavg_first_minute
        if test -r /proc/loadavg
            awk '{print $1}' /proc/loadavg
        else
            uptime | awk -F'load average: ' '{print $2}' | awk -F',' '{gsub(/ /,""); print $1}'
        end
    end

    #==============================#
    # Version gate                 #
    #==============================#
    set -l FISH_VER (string split ' ' -- (fish --version))[-1]
    if not __juniper_version_ge $FISH_VER $MIN_FISH_VERSION_REQUIRED
        __juniper_echo_error "Fish $MIN_FISH_VERSION_REQUIRED+ required. Detected: $FISH_VER"
        return 2
    end

    #==============================#
    # Argparse + flags             #
    #==============================#
    set -l _opts h/help v/verbose n/dry-run q/quick c/coverage o/open t/threads= s/seed=
    argparse -n juniper $_opts -- $argv
    or begin; __juniper_usage; return 2; end

    # Promote flags to globals so helpers can see them
    if set -q _flag_verbose;   set -g __juniper_flag_verbose 1; else set -e __juniper_flag_verbose; end
    if set -q _flag_dry_run;   set -g __juniper_flag_dry_run 1; else set -e __juniper_flag_dry_run; end
    if set -q _flag_quick;     set -g __juniper_flag_quick 1; set -x QUICK 1; else set -e __juniper_flag_quick; end
    if set -q _flag_coverage;  set -g __juniper_flag_coverage 1; else set -e __juniper_flag_coverage; end
    if set -q _flag_threads;   set -g __juniper_flag_threads $_flag_threads; else set -g __juniper_flag_threads ""; end
    if set -q _flag_seed;      set -g __juniper_flag_seed $_flag_seed; else set -e __juniper_flag_seed; end
    if set -q _flag_open;      set -g DEFAULT_AUTO_OPEN_OUTPUTS "1"; end

    set -l leftover $argv
    if test (count $leftover) -lt 1
        __juniper_usage; return 1
    end
    set -l subcommand $leftover[1]
    set -e leftover[1]

    #==============================#
    # Julia code emitters          #
    #==============================#
    function __juniper_code_init; echo 'using Pkg; Pkg.activate("."); Pkg.instantiate()'; end
    function __juniper_code_build; echo 'using Pkg; Pkg.activate("."); Pkg.build()'; end
    function __juniper_code_status; echo 'using Pkg; Pkg.activate("."); Pkg.status()'; end
    function __juniper_code_update; echo 'using Pkg; Pkg.activate("."); Pkg.resolve(); Pkg.update()'; end
    function __juniper_code_gc; echo 'using Pkg; Pkg.gc()'; end
    function __juniper_code_precompile; echo 'using Pkg; Pkg.activate("."); Pkg.precompile()'; end

    function __juniper_code_launch_pluto; echo "
        using Pkg
        Pkg.activate(\".\")
        let has_pluto = false
            try
                has_pluto = haskey(Pkg.project().dependencies, \"Pluto\")
            catch
                has_pluto = haskey(Pkg.dependencies(), \"Pluto\")
            end
            if !has_pluto
                @info \"Pluto not found in the project. Adding it.\"
                Pkg.add(\"Pluto\")
            else
                @info \"Pluto found. Launching.\"
            end
        end
        @info \"Launching Pluto notebook server\"
        using Pluto
        Pluto.run()
    "; end

    function __juniper_code_test
        set -l envs ""
        if set -q __juniper_flag_coverage; set envs "$envs\nENV[\"COVERAGE\"] = \"1\""; end
        if set -q __juniper_flag_seed;     set envs "$envs\nENV[\"JULIA_TEST_SEED\"] = string($(string $__juniper_flag_seed))"; end
        if test "$DEFAULT_FAST_TEST_FLAG" = "1" -o -n "$__juniper_flag_quick"; set envs "$envs\nENV[\"QUICK\"] = \"1\""; end
        echo "
            using Pkg
            $envs
            Pkg.activate(\".\")
            Pkg.test(; coverage = get(ENV, \"COVERAGE\", \"\") == \"1\")
        "
    end
    function __juniper_code_doctest; echo "
        using Pkg; Pkg.activate(\".\"); Pkg.instantiate()
        import TOML
        proj = TOML.parsefile(\"Project.toml\")
        name = Symbol(proj[\"name\"])
        mod = Base.require(name)
        try; using Documenter; catch; Pkg.add(\"Documenter\"); using Documenter; end
        @info \"Doctesting\" package=String(name)
        doctest(mod)
    "; end
    function __juniper_code_docs_noop; echo 'println("docs/make.jl not found — skipping docs build.")'; end
    function __juniper_code_coverage; echo "
        using Pkg; Pkg.activate(\".\"); Pkg.instantiate()
        try; using Coverage; catch; Pkg.add(\"Coverage\"); using Coverage; end
        cov = process_folder(\"src\")
        LCOV.writefile(\"lcov.info\", cov)
        println(\"Wrote lcov.info\")
    "; end
    function __juniper_code_format; echo "
        using Pkg; Pkg.activate(\".\"); Pkg.instantiate()
        try; using $DEFAULT_JULIA_FORMATTER_PKG; catch; Pkg.add(\"$DEFAULT_JULIA_FORMATTER_PKG\"); using $DEFAULT_JULIA_FORMATTER_PKG; end
        format(\".\"; verbose=true)
    "; end
    function __juniper_code_lint; echo "
        using Pkg; Pkg.activate(\".\"); Pkg.instantiate()
        import TOML
        proj = TOML.parsefile(\"Project.toml\")
        name = Symbol(proj[\"name\"])
        mod = Base.require(name)
        try; using $DEFAULT_JULIA_LINTER_PKG; catch; Pkg.add(\"$DEFAULT_JULIA_LINTER_PKG\"); using $DEFAULT_JULIA_LINTER_PKG; end
        Aqua.test_all(mod; ambiguities=true, deps_compat=true, stale_deps=true)
    "; end

    #==============================#
    # Commands                     #
    #==============================#
    function __juniper_cmd_docs
        if test -f $DOCS_MAKE_PATH
            __juniper_build_julia_command_with_threads
            if set -q __juniper_flag_dry_run
                echo $__JULIA_CMD $DOCS_MAKE_PATH
            else
                __juniper_log "$DOCS_MAKE_PATH"
                $__JULIA_CMD $DOCS_MAKE_PATH
            end
        else
            __juniper_run_julia_code (__juniper_code_docs_noop)
        end
    end
    function __juniper_cmd_repl
        __juniper_build_julia_command_with_threads
        if set -q __juniper_flag_dry_run
            echo $__JULIA_CMD
        else
            exec $__JULIA_CMD
        end
    end
    function __juniper_cmd_clean
        for pattern in $CLEAN_PATHS
            for hit in (ls -d $pattern ^/dev/null 2>/dev/null)
                __juniper_log "rm -rf $hit"
                if not set -q __juniper_flag_dry_run
                    rm -rf $hit
                end
            end
        end
        __juniper_echo_ok "Cleanup complete."
    end
    function __juniper_cmd_format_julia
        __juniper_run_julia_code (__juniper_code_format)
    end
    function __juniper_cmd_format_fish
        if test "$ENABLE_FISH_FORMAT_HELPER" != "1"
            __juniper_echo_info "Fish formatting helper disabled (ENABLE_FISH_FORMAT_HELPER != 1)."; return 0
        end
        if not type -q fish_indent
            __juniper_echo_error "fish_indent not found in PATH."; return 127
        end
        set -l targets $argv
        if test (count $targets) -eq 0
            set targets (functions -v juniper ^/dev/null 2>/dev/null)
        end
        for f in $targets
            if test -f "$f"
                if set -q __juniper_flag_dry_run
                    echo "fish_indent -w $f"
                else
                    fish_indent -w "$f"; __juniper_echo_ok "Formatted $f"
                end
            end
        end
    end
    function __juniper_cmd_rebuild_lsp_system_image
        mkdir -p (dirname $LSP_SYSIMAGE_PATH)
        mkdir -p (dirname $LSP_REBUILD_LOG_PATH)

        if not __juniper_quick_network_up
            __juniper_echo_info "Skipping LSP sysimage rebuild: offline"; return 0
        end

        set -l loadavg (__juniper_current_loadavg_first_minute)
        if test -n "$loadavg"
            if test (awk -v l="$loadavg" -v t="$SYSTEM_BUSY_LOAD_THRESHOLD" 'BEGIN{print (l>t)?1:0}') -eq 1
                __juniper_echo_info "Skipping LSP sysimage rebuild: system busy (load=$loadavg > $SYSTEM_BUSY_LOAD_THRESHOLD)"; return 0
            end
        end

        set -l ts (date "+%F %T")
        echo "[Julials Rebuild] Starting Rebuild @ $ts" | tee -a $LSP_REBUILD_LOG_PATH

        set -l julia_cmd "julia --threads=auto --startup-file=no --history-file=no -q --project=$LSP_PROJECT_ENV -e "
        set -l julia_code '
            using Pkg
            if isempty(Pkg.Registry.reachable_registries())
                Pkg.Registry.add("General")
            end
            required = ["LanguageServer","SymbolServer","StaticLint","PackageCompiler"]
            deps = try
                Pkg.project().dependencies
            catch
                Pkg.dependencies()
            end
            for name in required
                if !haskey(deps, name)
                    Pkg.add(name)
                end
            end
            Pkg.instantiate()
            using PackageCompiler
            pkgs = [:LanguageServer, :SymbolServer, :StaticLint]
            create_sysimage(pkgs; sysimage_path = "'$LSP_SYSIMAGE_PATH'", incremental = false)
            println("[Julials Rebuild] Sysimage Rebuilt Successfully At '$LSP_SYSIMAGE_PATH'")
        '
        if set -q __juniper_flag_dry_run
            echo $julia_cmd\"$julia_code\" ">>" $LSP_REBUILD_LOG_PATH
        else
            eval $julia_cmd\"$julia_code\" >> $LSP_REBUILD_LOG_PATH 2>&1
        end

        set -l te (date "+%F %T")
        echo "[Julials Rebuild] Done @ $te" | tee -a $LSP_REBUILD_LOG_PATH
        if test -f "$LSP_SYSIMAGE_PATH"
            __juniper_echo_ok "LSP sysimage rebuilt at $LSP_SYSIMAGE_PATH"
        else
            __juniper_echo_error "LSP sysimage rebuild finished but file not found at $LSP_SYSIMAGE_PATH"; return 1
        end
    end

    #==============================#
    # Dispatch                     #
    #==============================#
    switch $subcommand
        case init;         __juniper_run_julia_code (__juniper_code_init)
        case build;        __juniper_run_julia_code (__juniper_code_build)
        case test;         __juniper_run_julia_code (__juniper_code_test)
        case repl;         __juniper_cmd_repl
        case doctest;      __juniper_run_julia_code (__juniper_code_doctest)
        case docs;         __juniper_cmd_docs
        case status;       __juniper_run_julia_code (__juniper_code_status)
        case update;       __juniper_run_julia_code (__juniper_code_update)
        case gc;           __juniper_run_julia_code (__juniper_code_gc)
        case precompile;   __juniper_run_julia_code (__juniper_code_precompile)
        case clean;        __juniper_cmd_clean
        case pluto;        __juniper_run_julia_code (__juniper_code_launch_pluto)
        case format
            if test (count $leftover) -ge 1
                switch $leftover[1]
                    case fish;  set -e leftover[1]; __juniper_cmd_format_fish $leftover
                    case julia; __juniper_cmd_format_julia
                    case '*';   __juniper_echo_error "unknown formatter: $leftover[1] (use 'julia' or 'fish')"; return 1
                end
            else
                __juniper_cmd_format_julia
            end
        case lint;         __juniper_run_julia_code (__juniper_code_lint)
        case ci
            __juniper_run_julia_code (__juniper_code_init); or return $status
            __juniper_run_julia_code (__juniper_code_build); or return $status
            set -g __juniper_flag_coverage 1
            __juniper_run_julia_code (__juniper_code_test); or return $status
            __juniper_run_julia_code (__juniper_code_doctest)
        case coverage;     __juniper_run_julia_code (__juniper_code_coverage)
        case rebuild_lsp_system_image; __juniper_cmd_rebuild_lsp_system_image
        case -h --help help; __juniper_usage
        case '*'
            __juniper_echo_error "Unknown subcommand: $subcommand"; __juniper_usage; return 1
    end
end

