# niri notes

## ASUS function keys

The laptop firmware translates several physical function keys before niri sees them:

| Physical key | Niri binding         | Action                                                            |
| ------------ | -------------------- | ----------------------------------------------------------------- |
| `Fn+F4`      | `XF86Launch3`        | Toggle `Integrated` and `Hybrid` graphics modes                   |
| `Fn+F6`      | `Mod+Shift+S`        | Select an area, save it under `Pictures/Screenshots`, and copy it |
| `Fn+F9`      | `Mod+P`              | Move the focused window to the next monitor                       |
| `Fn+F10`     | `XF86TouchpadToggle` | Unbound                                                           |

`Fn+F4` only switches between `Integrated` and `Hybrid`. Anything else, including `AsusEgpu`, is left alone so an attached XG Mobile never disconnects by accident.

`Mod+F6` selects an area and copies it without saving a file.
