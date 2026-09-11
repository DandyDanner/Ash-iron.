# Character and wildlife modeling studio

Open `cycles/cycle_26/characters.blend` for the latest eight-model studies in Blender 5.2.1 LTS. See [the cycle review](cycles/REVIEW.md) for the actual renders, improvements, and remaining limitations. These models are not rigged or integrated into the game.

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

## Latest wildlife study

`tools/blender/refine_wildlife.py` loads cycle 15 and preserves its travelers while rebuilding animals. To reproduce the cycle 19 checkpoint in a fresh folder, use `Blender --background --factory-startup --python tools/blender/refine_wildlife.py -- --art-pass=99 --refinement=4`. It refuses to overwrite a saved source. Do not use this baseline-based reconstruction to overwrite later traveler or animal edits.

`Blender --background --factory-startup --python tools/blender/render_wildlife_details.py -- --art-pass=19` renders rear and face inspection views from that saved source without modifying the `.blend` file. The ordinary wildlife generator also renders full silhouettes and portrait/side pairs. All images are actual Cycles renders.

For the cycle 20 attachment cleanup, `Blender --background --factory-startup --python tools/blender/polish_wildlife_attachments.py -- --art-pass=99` loads the saved cycle 19 animals and corrects antler/ear seating, eye/fur clearance and hoof finish. It preserves the saved traveler models and refuses to overwrite an existing source. Use `render_wildlife_details.py -- --art-pass=20` for the latest close views.

## Latest traveler studies

Cycle 26 preserves the cycle 20 wildlife and includes revised eyelids, cupped ears, sloped jaws, fitted lips, freckles, finer graded stubble, narrower hanging capes, fitted straps and scalp-following wayfarer braids. These remain simplified offline studies. [The morning review](../../docs/art/OVERNIGHT_REVIEW.md) links actual renders and the largest remaining differences from the illustrations.

The versioned scripts intentionally read specific saved baselines and refuse to overwrite existing sources:

- `refine_traveler_expression.py -- --art-pass=99 --refinement=2` reproduces the cycle 22 face checkpoint from cycle 20.
- `refine_cape_silhouettes.py -- --art-pass=99 --refinement=5` reproduces the cycle 24 cape/stubble checkpoint from cycle 22.
- `fit_wayfarer_braids.py -- --art-pass=99 --refinement=3` reproduces cycle 26 braid/cloth-contact corrections from cycle 24.

Prefix each with `Blender --background --factory-startup --python tools/blender/` and use a different unused pass number for each run. For new work, load **cycle 26** directly; do not regenerate from an earlier baseline and discard later edits. Face details for unchanged scout/forager faces are in cycle 22, ranger details in cycle 24, and wildlife details in cycle 20. Cycle 26 has current traveler front/rear lineups, wayfarer face/profile/rear views, both cape closeups and a scout side view.

Render an overview directly from the latest saved source with `Blender --background --factory-startup --python tools/blender/render_study_overview.py -- --art-pass=26`. This writes `all-eight.png` without changing the native file.
