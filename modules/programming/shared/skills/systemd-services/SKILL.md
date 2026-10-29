---
name: systemd-services
description: Configure or troubleshoot systemd services, user units, timers, dependencies, and journal logs, including declarative Nix-managed units.
---

# Systemd services

Identify whether the unit belongs to the system or a user manager and how it is generated before changing it. For Nix-managed units, edit the owning module and follow its activation workflow instead of editing generated files. Inspect unit status, the journal, timer state, and the effective unit as needed; distinguish current runtime state from configuration waiting to be activated.

Add ordering and requirement dependencies only when the service actually needs them: `After=` orders units and does not start them, while `Wants=` and `Requires=` express dependencies. Select service type, restart behavior, sandboxing, and writable paths to match the process. Check timers separately from the jobs they trigger.

Use `systemd-analyze verify` or the project's build checks when available, recognizing that validation outside the target environment may lack generated units or dependencies. Report unverified runtime behavior. Starting, restarting, or enabling a unit changes live state; do so only within the task's authorized scope and account for active jobs.

In this dotfiles repository, consult `docs/rebuild.md` and the owning module for Home Manager user timer activation and restart behavior before recommending commands.
