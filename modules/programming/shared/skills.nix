{pkgs, ...}: let
  matt-pocock-skills = pkgs.fetchFromGitHub {
    owner = "fullheart";
    repo = "mattpocock-skills-opencode";
    rev = "82394f3398ee7623a158a9b2fde088e558a30e35";
    hash = "sha256-6/M/JXflTTZ1FtrhdBWS5k8uYZgtHlP+yy8m63u+oNg=";
  };
  julia-skills = pkgs.fetchFromGitHub {
    owner = "Krastanov";
    repo = "JuliaLLMAgentSkills";
    rev = "3dd1163515dd3df990a31c4df59d1d984ee725b4";
    hash = "sha256-OlztOj3QWU83d6bugIrUFoilTSDbG9OCnXWmV/ZvI80=";
  };
  scientific-skills = pkgs.fetchFromGitHub {
    owner = "K-Dense-AI";
    repo = "scientific-agent-skills";
    rev = "209390194c85b3466259853417eeac81ea4f0976";
    hash = "sha256-e7FQELopdQw6zvu2sQoatcazFQtudpC2JR4Gu5MmXI8=";
  };
  ponytail-skills = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b";
    hash = "sha256-Y7d4s7uqjH6IbEXhqAiQ+yaxr6iiGcv2X64LuMtG1T8=";
  };
  j13z-svelte-essentials = pkgs.fetchFromGitHub {
    owner = "j13z";
    repo = "j13z-svelte-essentials";
    rev = "7902fa32399e3ab5aa07b6121bd19e285fa9dde3";
    hash = "sha256-5UmuvV5X9BvGhmgXviodLj7C4ROSGe3zhpR1oRVCqbg=";
  };
  ag-opencode-skills = pkgs.fetchFromGitHub {
    owner = "harshahosur81";
    repo = "ag-opencode-skills";
    rev = "a2265b428dce31e5f1a85c06f91ad0d6e9cf14cc";
    hash = "sha256-yUjoUmdG3ZnlPVW4eKxlrwA67ejeOZdq/y3Zoy++Zuo=";
  };
  cloudflare-skills = pkgs.fetchFromGitHub {
    owner = "cloudflare";
    repo = "skills";
    rev = "70215303d44a81a0db3219428f4825b604fc6061";
    hash = "sha256-3aVvQoM/n7MOkYg0j+yfP+6Pkqf8oB8ycVS2M2umuNU=";
  };
  tstack = pkgs.fetchFromGitHub {
    owner = "t3dotgg";
    repo = "tstack";
    rev = "11e37a74d0a6868c121cd0910ab2b3bd9873b92a";
    hash = "sha256-1N0fxvcM44NcGOZeYJiX/EAJuI9GoAj5rEXmu7mJc3w=";
  };
  # Upstream pstack is a Cursor plugin. This port tracks it with harness
  # mappings for Claude Code, Codex, Copilot CLI, and OpenCode.
  pstack = pkgs.fetchFromGitHub {
    owner = "michael-denyer";
    repo = "pstack-claude";
    rev = "412990b837ddb5e41ee589d770ba1bff24144654";
    hash = "sha256-ZrXpvZIJgmbRO6n3//G/cg3/yc75XtQ8b+xzdxpOEv0=";
  };
  pstackSkills = let
    skillsDir = "${pstack}/plugins/pstack/skills";
    # Keep the existing tdd skill instead of shadowing it with pstack's copy;
    # poteto-mode can still route to the installed tdd workflow.
    skillNames = builtins.filter (name: name != "tdd") (builtins.attrNames (builtins.readDir skillsDir));
  in
    builtins.listToAttrs (map (name: {
        inherit name;
        value = "${skillsDir}/${name}";
      })
      skillNames);
  # Copilot rejects SKILL.md descriptions over 1024 characters. The upstream
  # scientific pack's description is longer, so keep its body and shorten only
  # the discovery metadata.
  experimentalDesignSkill = pkgs.runCommandLocal "experimental-design-skill" {} ''
    cp -R ${scientific-skills}/skills/experimental-design $out
    chmod -R u+w $out
    ${pkgs.perl}/bin/perl -0pi -e 's/^description: .*$/description: Design experiments and studies before collecting data; randomization, blocking, controls, factorial and fractional-factorial designs, response-surface optimization, crossover and repeated-measures designs, cluster randomization, and sample layouts. Use when planning a study, assigning subjects or samples to groups, avoiding confounding, or choosing a design of experiments (DOE). For sample size or power after the design is chosen, use statistical-power; for analyzing collected data, use statistical-analysis./m' $out/SKILL.md
  '';
  baseSkills = {
    # keep-sorted start
    "aeon" = "${scientific-skills}/skills/aeon";
    "agents-sdk" = "${cloudflare-skills}/skills/agents-sdk";
    "astropy" = "${scientific-skills}/skills/astropy";
    "autoskill" = "${scientific-skills}/skills/autoskill";
    "babysit-pr" = "${tstack}/skills/babysit-pr";
    "citation-management" = "${scientific-skills}/skills/citation-management";
    "cloudflare" = "${cloudflare-skills}/skills/cloudflare";
    "cloudflare-email-service" = "${cloudflare-skills}/skills/cloudflare-email-service";
    "cloudflare-one" = "${cloudflare-skills}/skills/cloudflare-one";
    "cloudflare-one-migrations" = "${cloudflare-skills}/skills/cloudflare-one-migrations";
    "council" = "${tstack}/skills/council";
    "dask" = "${scientific-skills}/skills/dask";
    "database-lookup" = "${scientific-skills}/skills/database-lookup";
    "docx" = "${scientific-skills}/skills/docx";
    "durable-objects" = "${cloudflare-skills}/skills/durable-objects";
    "exa-search" = "${scientific-skills}/skills/exa-search";
    "experimental-design" = experimentalDesignSkill;
    "exploratory-data-analysis" = "${scientific-skills}/skills/exploratory-data-analysis";
    "file-pr" = "${tstack}/skills/file-pr";
    "fluidsim" = "${scientific-skills}/skills/fluidsim";
    "full-send" = "${tstack}/skills/full-send";
    "full-stop" = "${tstack}/skills/full-stop";
    "generate-image" = "${scientific-skills}/skills/generate-image";
    "get-available-resources" = "${scientific-skills}/skills/get-available-resources";
    "grill-me" = "${matt-pocock-skills}/grill-me";
    "gtars" = "${scientific-skills}/skills/gtars";
    "hugging-science" = "${scientific-skills}/skills/hugging-science";
    "improve-codebase-architecture" = "${matt-pocock-skills}/improve-codebase-architecture";
    "infographics" = "${scientific-skills}/skills/infographics";
    "julia-bench" = "${julia-skills}/julia-bench";
    "julia-comonicon" = "${julia-skills}/julia-comonicon";
    "julia-csv" = "${julia-skills}/julia-csv";
    "julia-docs" = "${julia-skills}/julia-docs";
    "julia-external-cmd" = "${julia-skills}/julia-external-cmd";
    "julia-github" = "${julia-skills}/julia-github";
    "julia-jet" = "${julia-skills}/julia-jet";
    "julia-makie-recipes" = "${julia-skills}/julia-makie-recipes";
    "julia-package-dev" = "${julia-skills}/julia-package-dev";
    "julia-perf" = "${julia-skills}/julia-perf";
    "julia-prettytables" = "${julia-skills}/julia-prettytables";
    "julia-scratch" = "${julia-skills}/julia-scratch";
    "julia-term" = "${julia-skills}/julia-term";
    "julia-tests" = "${julia-skills}/julia-tests";
    "julia-threads" = "${julia-skills}/julia-threads";
    "julia-toml" = "${julia-skills}/julia-toml";
    "julia-yaml" = "${julia-skills}/julia-yaml";
    "latex-posters" = "${scientific-skills}/skills/latex-posters";
    "leaving-pr-comments" = "${tstack}/skills/leaving-pr-comments";
    "linux-desktop" = ./skills/linux-desktop;
    "literature-review" = "${scientific-skills}/skills/literature-review";
    "markdown-mermaid-writing" = "${scientific-skills}/skills/markdown-mermaid-writing";
    "markitdown" = "${scientific-skills}/skills/markitdown";
    "matlab" = "${scientific-skills}/skills/matlab";
    "matplotlib" = "${scientific-skills}/skills/matplotlib";
    "modal" = "${scientific-skills}/skills/modal";
    "modernize" = "${tstack}/skills/modernize";
    "neovim-configuration" = ./skills/neovim-configuration;
    "networkx" = "${scientific-skills}/skills/networkx";
    "nextflow" = "${scientific-skills}/skills/nextflow";
    "nix-configuration" = ./skills/nix-configuration;
    "open-notebook" = "${scientific-skills}/skills/open-notebook";
    "optimize-for-gpu" = "${scientific-skills}/skills/optimize-for-gpu";
    "paper-lookup" = "${scientific-skills}/skills/paper-lookup";
    "paperzilla" = "${scientific-skills}/skills/paperzilla";
    "parallel-web" = "${scientific-skills}/skills/parallel-web";
    "pdf" = "${scientific-skills}/skills/pdf";
    "peer-review" = "${scientific-skills}/skills/peer-review";
    "polars" = "${scientific-skills}/skills/polars";
    "ponytail" = "${ponytail-skills}/skills/ponytail";
    "pptx" = "${scientific-skills}/skills/pptx";
    "pptx-posters" = "${scientific-skills}/skills/pptx-posters";
    "pymc" = "${scientific-skills}/skills/pymc";
    "pymoo" = "${scientific-skills}/skills/pymoo";
    "pytorch-lightning" = "${scientific-skills}/skills/pytorch-lightning";
    "pyzotero" = "${scientific-skills}/skills/pyzotero";
    "research-grants" = "${scientific-skills}/skills/research-grants";
    "research-lookup" = "${scientific-skills}/skills/research-lookup";
    "rowan" = "${scientific-skills}/skills/rowan";
    "rust-development" = ./skills/rust-development;
    "sandbox-sdk" = "${cloudflare-skills}/skills/sandbox-sdk";
    "scholar-evaluation" = "${scientific-skills}/skills/scholar-evaluation";
    "scientific-brainstorming" = "${scientific-skills}/skills/scientific-brainstorming";
    "scientific-critical-thinking" = "${scientific-skills}/skills/scientific-critical-thinking";
    "scientific-schematics" = "${scientific-skills}/skills/scientific-schematics";
    "scientific-slides" = "${scientific-skills}/skills/scientific-slides";
    "scientific-visualization" = "${scientific-skills}/skills/scientific-visualization";
    "scientific-writing" = "${scientific-skills}/skills/scientific-writing";
    "scikit-learn" = "${scientific-skills}/skills/scikit-learn";
    "seaborn" = "${scientific-skills}/skills/seaborn";
    "shadcn-svelte" = "${j13z-svelte-essentials}/agent-skills/dist/shadcn-svelte";
    "shap" = "${scientific-skills}/skills/shap";
    "simpy" = "${scientific-skills}/skills/simpy";
    "sol-loop" = "${tstack}/skills/sol-loop";
    "stable-baselines3" = "${scientific-skills}/skills/stable-baselines3";
    "statistical-analysis" = "${scientific-skills}/skills/statistical-analysis";
    "statistical-power" = "${scientific-skills}/skills/statistical-power";
    "statsmodels" = "${scientific-skills}/skills/statsmodels";
    "svelte-authoring" = "${j13z-svelte-essentials}/agent-skills/dist/svelte-authoring";
    "svelte-review" = "${j13z-svelte-essentials}/agent-skills/dist/svelte-review";
    "sympy" = "${scientific-skills}/skills/sympy";
    "systemd-services" = ./skills/systemd-services;
    "tailwind-design-system" = "${ag-opencode-skills}/skills/frontend/tailwind-design-system";
    "takeover" = "${tstack}/skills/takeover";
    "tdd" = "${matt-pocock-skills}/tdd";
    "timesfm-forecasting" = "${scientific-skills}/skills/timesfm-forecasting";
    "torch-geometric" = "${scientific-skills}/skills/torch-geometric";
    "transformers" = "${scientific-skills}/skills/transformers";
    "turnstile-spin" = "${cloudflare-skills}/skills/turnstile-spin";
    "umap-learn" = "${scientific-skills}/skills/umap-learn";
    "vaex" = "${scientific-skills}/skills/vaex";
    "venue-templates" = "${scientific-skills}/skills/venue-templates";
    "web-perf" = "${cloudflare-skills}/skills/web-perf";
    "what-if-oracle" = "${scientific-skills}/skills/what-if-oracle";
    "whitespace" = "${julia-skills}/whitespace";
    "workers-best-practices" = "${cloudflare-skills}/skills/workers-best-practices";
    "wrangler" = "${cloudflare-skills}/skills/wrangler";
    "write-a-skill" = "${matt-pocock-skills}/write-a-skill";
    "xlsx" = "${scientific-skills}/skills/xlsx";
    "zarr-python" = "${scientific-skills}/skills/zarr-python";
    # keep-sorted end
  };
in {
  dotfiles.programming.agents.skills = baseSkills // pstackSkills;
}
