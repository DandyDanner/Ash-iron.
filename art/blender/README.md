# Character and wildlife modeling studio

Open `cycles/cycle_12/characters.blend` for the latest eight-model studies in Blender 5.2.1 LTS. See [the cycle review](cycles/REVIEW.md) for the actual renders, improvements, and remaining limitations. These models are not rigged or integrated into the game.

`ash_iron_character_studio.blend` remains the original baseline.

The original studio contains the **existing prototypes as a scale/rig baseline**, not newly sculpted or finished replacement characters. The approved Willow Scout turnaround and wildlife concept sheet are packed into the file. The wildlife target is panel #1, Bristleback.

The original studio models are in separate named collections. Toggle the screen icon for **APPROVED REFERENCES** to show the reference images, placed beside the models. Studio lights, camera, and floor are review aids, hidden in the modeling viewport and excluded from the exported check file. The internal text **START HERE — Character and Boar.txt** records scope and next steps.

## Scope

Build all four approved traveler designs and all four approved wildlife studies toward the approved illustrations, then assess actual front/side/back renders before replacing the playable models. Keep customization, equipment contacts, animation, and scale in mind. Do not change the world or combat while doing this art work.

Save new authored versions under distinct names so this baseline remains available. The `.gdignore` keeps this entire source folder out of Godot’s asset importer. No scene currently loads these files. Finished approved GLBs will eventually go under `assets/` with explicit integration.

## Reproduce and verify

From the repository root:

1. `Godot --headless --path . --script res://tools/blender/export_baseline.gd`
2. `Blender --background --factory-startup --python tools/blender/create_studio.py`
3. `Godot --headless --path . --script res://tools/blender/check_import.gd`

Use the installed executable paths on the Mac: `/Users/dallonanderson/Downloads/Godot.app/Contents/MacOS/Godot` and `/Applications/Blender.app/Contents/MacOS/Blender`.

The exporter removes hidden prototype nodes from the comparison copy: Blender 5.2.1 does not accept Godot’s required `KHR_node_visibility` extension. This does not alter gameplay source or the live character. The round-trip check validates the exported mesh presence and dimensions in Godot; it is not a fidelity, skinning, or animation approval.

The setup script refuses to overwrite an existing studio by default. Rebuilding the generated comparison file requires `-- --replace-baseline`. Preserve any manual art edits in a separate authored `.blend` file first.
