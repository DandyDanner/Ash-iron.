# Local patches to RodinBridge

Source: https://github.com/DeemosTech/Godot-Rodin-Plugin (`addons/RodinBridge`, version 0.1.0,
last upstream commit 2025-08-25, Apache-2.0; the LICENSE file is copied alongside).

Applied 2026-09-11 so the addon loads on Godot 4.7.2. Upstream still ships the unpatched version.

1. `rodin_bottom_panel.tscn`: removed `class_name ...` from the eight scripts embedded in the
   scene. Newer Godot rejects `class_name` in built-in scripts ("class_name isn't allowed in
   built-in scripts"), which left every widget in the Rodin dock without its script. Nothing
   referenced those class names, so only the `class_name X` prefix was dropped from each
   `extends` line.
2. `rodin_bridge.gd`, `_exit_tree`: `remove_control_from_bottom_panel(panel)` changed to
   `remove_control_from_docks(panel)`, matching the `add_control_to_dock` call in
   `_enter_tree`. The old call logged an `item_idx == -1` error when the plugin unloaded.

Everything else matches upstream byte-for-byte. Line endings were normalized to LF (the downloaded zip shipped CRLF; upstream itself is LF).
