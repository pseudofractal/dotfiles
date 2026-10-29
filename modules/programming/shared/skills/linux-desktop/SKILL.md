---
name: linux-desktop
description: Diagnose or change Linux desktop integration, including Wayland compositors, displays, graphics, input devices, and user-session services.
---

# Linux desktop integration

Identify the host, compositor, session, and configuration owner before changing behavior. Trace a symptom across the relevant declarative configuration, session environment, user services, drivers, and hardware. Use read-only status and logs where available; distinguish observations from hypotheses and check the effect of a change on the target session.

Avoid assuming that a configuration build proves graphics, display, input, or hotplug behavior. Test the narrowest relevant path when hardware and a session are available, and explain any required reload or new login and any unverified behavior. Preserve existing display and input arrangements and avoid disruptive session or hardware changes outside the requested task.

For this dotfiles repository, inspect `modules/desktop/niri`, `docs/niri.md`, `docs/keybinds/niri.md`, and `docs/rebuild.md` as relevant. Check both Home Manager and System Manager ownership when diagnosing the niri session or graphics integration. Other desktops and Android need their own applicable configuration.
