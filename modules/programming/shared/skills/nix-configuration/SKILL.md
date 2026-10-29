---
name: nix-configuration
description: Work on Nix expressions, flakes, NixOS, Home Manager, System Manager, or Nix-on-Droid configuration. Use for module changes, package definitions, evaluation, builds, and troubleshooting.
---

# Nix configuration

Inspect the target host, existing modules, pinned inputs, and repository instructions before changing configuration. Follow the project's module layout and package sources. Verify options against the project's pinned inputs or evaluated configuration; an installed system or online manual may describe a different revision.

Choose verification appropriate to the change: parse or format the expression, evaluate the relevant output, then build the affected target when practical. Report the exact checks and any environment limitations. A successful parse alone does not validate module options or a build.

Activation changes a live environment. Distinguish evaluation, building, and activation, and use the project's documented workflow and the user's authorization. Do not update unrelated flake inputs, garbage-collect generations, or change secrets as part of an unrelated task.

For this dotfiles repository, read `docs/rebuild.md` and `modules/core/fish/functions/rebuild.fish` before changing or recommending activation. Desktop Home Manager, System Manager, and Nix-on-Droid have different targets and side effects. Check current documentation and implementation rather than assuming this is NixOS or running `nixos-rebuild`.
