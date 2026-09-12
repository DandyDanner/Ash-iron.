# Supplied trees, chest and ore — 2026-09-11

Actual Godot captures: [pine](imported-props/pine-close.png), [forest](imported-props/forest.png), [stone/copper/iron](imported-props/ore-variants.png), [closed chest](imported-props/chest-closed.png), [open chest](imported-props/chest-open.png).

These are native game renders, not concept pictures. The labeled ore lineup and close-up chest are temporary preview fixtures; normal deposits and placed chests use the same assets/materials.

## Integrated art

- **Tree:** the supplied textured pine replaces harvest-tree and character-stage pine art. Near mesh: 8,000 triangles; distant mesh: 1,400. The switch is at 28 m with hysteresis. Height is approximately 5.1 m, with small deterministic rotation/height variations. Tree positions, four-hit chopping, falling, stump collision, five-wood drops and saved depletion retain their existing behavior. Existing simple stumps remain.
- **Chest:** supplied plank/strap exterior, split lid at a fixed rear pivot, and a newly built hollow interior. Approximately 9,528 triangles total. Fitted to the existing 0.92 × 0.62 × 0.58 m closed footprint. The lid uses the existing quarter-second opening/closing tween; storage, placement, transfer, linked crafting and persistence are unchanged. Dropped chest items use a small version of the same mesh.
- **Stone and ores:** the supplied jagged cluster is shared by boulders, copper/iron outcrops, loose mined/gathered fragments, small forest rocks and the two permanent Bellmaw cover rocks. Near mesh: 5,999 triangles; distant mesh: 900, switching at 22 m. Stone is neutral gray; copper has warm orange seams and green weathering; iron has a dark gray base with lighter mineral seams. Source surface and normal detail are retained. The stone and ore inventory icons use matching colors.

The three PBR exports use packed 1K textures, with Godot's extracted textures/import settings also checked in. Material resources and mesh resources are reused across instances. Total packed GLBs are about 5.05 MiB. The uploaded ZIP with the UUID name is the same chest file, not an additional prop.

Source preparation is reproducible with `tools/blender/prepare_imported_props.py` (instructions in its docstring). Editable sources and input SHA-256 hashes are in `art/blender/imported_props/`. Original downloads remain unchanged.

## Validation and limits

All 27 headless suites pass. The new prop suite checks geometry budgets, near/far ranges, textures, distinct mineral palettes, a true open chest cavity with a floor, the fixed lid hinge, closing without changing contents, and depleted tree/rock/ore plus chest restoration. Existing tests cover actual chopping/mining, falls, weapon obstruction, placement, transfer, linked crafting/smelting and old saves.

Native review caught and corrected an inverted/solid chest cavity, inner walls that covered the exterior planks, and overly bright tree/rock materials. Final captures show the corrected interior and colors. Native preview completed without script/render errors. Headless macOS still reports its known certificate lookup warning; recovery-mode import cannot save global editor settings inside the sandbox, but resource import completes.

Collision footprints deliberately retain the established gameplay shapes, including permanent Bellmaw cover; they do not trace individual rock spikes or leaves. Generated geometry/UVs retain some rough seams, and the interior uses simple wood surfaces. The distance meshes can visibly switch as you approach; there is no wind animation in these tree meshes yet. These are practical game assets, not final hand-authored environment art.

This art pass adds no resource types or progression tiers. Stone/copper/iron yields, placement positions, terrain, lighting, combat and save format 12 are unchanged. Traveler and enemy models are preserved.
