# Face and rendering pass (2026-09-12)

Claude's pass after Codex's Rodin party integration: make the traveler faces read at close range and make the clearing richer, without dropping below 60 fps on Dallon's Apple M2 at retina resolution.

## Actual captures

| View | Before | After |
|---|---|---|
| Clearing, third person | [Compatibility renderer](rendering-pass/clearing-before-compatibility.png) | [Forward+](rendering-pass/clearing-after-forward-plus.png) |
| Willow, in-game close-up | [Shared atlas](rendering-pass/willow-face-before.png) | [Face maps](rendering-pass/willow-face-after.png) |
| Creator face view | — | [After](rendering-pass/creator-face-after.png) |
| Willow face albedo | — | [1024 map](rendering-pass/willow-face-albedo.png) |

All four faces and idle views on the new renderer: `rodin-party/game-N-face.png` and `game-N-idle.png` (N = 0 Willow, 1 Ranger, 2 Wayfarer, 3 Ember). Blender studio renders of the exported meshes: `rodin-party/<slug>-face.png` and `four-travelers.png`.

## What was measured before deciding

- Godot 4 enables hiDPI by default, so the 1280x800 window renders 2560x1600 pixels on this Mac (screen scale 2.0). Every budget number below was taken at that internal resolution (`scaling_3d_scale = 2.0`) in third person in the clearing, after a warm-up pass so shader compilation stayed out of the rows. macOS pins both the Metal and Vulkan drivers at the display rate even with vsync disabled, so a row at 16.7 ms means "holds 60"; only rows above it are informative.

| Configuration at 2x | Frame time |
|---|---|
| Compatibility renderer, previous settings | 16.0 ms (about 62 fps, no headroom) |
| Forward+, previous settings | holds 60 |
| Forward+ + soft shadows + ACES + glow + SSAO | holds 60 |
| Forward+ + SDFGI | 18.2 ms (55 fps) |
| Forward+ + SSIL instead of SDFGI | 18.0 ms (55 fps) |

- Willow's eye occupied 14 texels of the shared 2048 atlas. No painting technique can make lids, sclera and iris read at that density.
- `authored_traveler.gd` only refined materials named `Game Skin` / `Game Fabric`. The Rodin exports are named `Rodin Skin` / `Rodin Fabric` (numbered `.001`… on the second to fourth figures), so the surface grain never applied to them.
- Under Forward+, Codex's exact environment values rendered pale. Patch sampling of the sunlit meadow showed the cause: the compatibility renderer shades in gamma space, so the raw float colors in `meadow.gdshader` and `meadow_grass.gdshader` had been tuned as display values. Forward+ treats them as linear, which brightens and desaturates them. Fog and the tonemapper were not the cause; converting those constants to linear restored the saturated greens (sunlit patch 0.54/0.64/0.31 on compatibility, 0.45/0.52/0.22 after the fix on Forward+ with ACES).

## What changed

1. **Renderer.** `rendering_method = forward_plus`; mobile stays on compatibility. FXAA on top of 2x MSAA. Every environment property used is ignored on compatibility, so nothing breaks there; the picture simply stays flat.
2. **Clearing lighting** (`visual_clearing.gd`). ACES tonemap at exposure 1.0, cool ambient color at 0.42 with sky reflections, sun at 1.15 with 0.6 degree angular size, tuned bias and 4 split cascades to 55 m, SSAO (radius 0.9, intensity 2.2), subtle soft-light glow, exponential fog at 0.0015 with aerial perspective. No SDFGI, no volumetric fog.
3. **Meadow shaders.** Colors converted to linear with a comment explaining why.
4. **Face maps** (`tools/blender/rodin_party_face.py`, called from `prepare_rodin_party.py` after the body atlas bake). Head skin polygons (centroid above 1.58 m, near the head landmark) move to a `Rodin Face` material. Their UV islands are repacked into the unit square by a deterministic shelf packer, because Blender's pack operator repacks the whole mesh from a background script and detaches the body from its baked atlas. The head is rasterized at 1024 (about a third of the square covered; Willow's eye is now about 100 texels wide) and painted from the same front-view landmarks as the atlas: painted light from above (undersides darken), skin mottling, socket shading, cheek/nose/ear warmth, almond eyes with sclera, limbal ring, fibered iris, pupil, catchlight and secondary reflection, lid shadow on the eyeball, tapered lash lines, lid fold, lower lashes, tear duct, tapered arched brows, cupid's bow lips with a highlight and a slight smile, nostril dips. Height field to tangent-space normals (lid bulges, lash grooves, brow ridge, lips, philtrum, cornea bulge). Roughness: eyes 0.12, lips 0.45, T-zone 0.52, skin 0.62. The body atlas keeps fine strand streaks on hair.
5. **Runtime materials** (`surface_detail.dress()`). Skin and face: subsurface scattering, specular 0.4. Body skin, fabric and leather: the existing grain normal on the multiplied UV2 triplanar detail layer, so the painted UV1 maps stay intact. Hair: roughness 0.55. Face keeps its own normal map (no grain overlay).
6. **Creator stage.** ACES, SSAO, softer sun, FXAA.
7. **Tests.** `traveler_selection_test` accepts the 1024 face texture; `rendering_pass_test` checks the renderer setting, clearing and creator flags, dressed materials and the face maps on all four exports.

## Rebuild and verify

- Blender 5.2.1: `Blender --background --factory-startup --python-exit-code 1 --python tools/blender/prepare_rodin_party.py -- /path/to/Travelers.glb` rebuilds all four exports, face maps and the studio renders in about two minutes. `--only=0 --no-render` iterates on Willow in about 20 seconds.
- Godot 4.7.2: `Godot --headless --recovery-mode --import --path .`, then the 30 headless suites in `README.md`. `tests/rendering_preview.gd` captures the clearing and creator; `tests/rodin_travelers_preview.gd` captures the four faces; `tests/rendering_budget.gd` reprints the budget ladder.

## Limits and next steps

- The retina budget has no room for SDFGI. Bounce light would need baking or a 1.5x internal scale.
- Hair still reads as a solid cap at close range; strand streaks are subtle on dark hair. A hair normal map or lighter hair palettes would help.
- The shelf packer covers about a third of each face map; rotating and nesting islands could double texel density for free.
- Retopology, facial animation, moving eyeballs and equipment separation remain on Codex's list in `RODIN_PARTY_REVIEW.md`.
