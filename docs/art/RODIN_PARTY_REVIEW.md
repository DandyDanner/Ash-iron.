# Rodin travelers: color and game integration

The four selectable travelers now come from Dallon's uncolored `Travelers.glb`. The original download is unchanged. The four large connected figures were kept; the four miniature figures from the sheet and two tiny loose fragments were discarded. This replaces the older Willow-only Rodin export and the three procedural Blender exports, while retaining the original Custom Scout choice and the existing profile/world saves.

## Actual models

[Four travelers together, rendered in Blender](rodin-party/four-travelers.png). These are the exported game meshes, with studio lighting; the game's current outdoor lighting looks different.

| Traveler | Front / face | Actual Godot view / equipment |
|---|---|---|
| Willow Scout | [Full figure](rodin-party/willow_scout-front.png), [face](rodin-party/willow_scout-face.png) | [In game](rodin-party/game-0-idle.png), [axe](rodin-party/game-0-held-stone_axe.png), [bow](rodin-party/game-0-held-bow.png) |
| Hearthland Ranger | [Full figure](rodin-party/hearthland_ranger-front.png), [face](rodin-party/hearthland_ranger-face.png) | [In game](rodin-party/game-1-idle.png), [axe](rodin-party/game-1-held-stone_axe.png), [walk](rodin-party/game-1-stride.png), [jaw side](rodin-party/game-1-face-side-1.png), [opposite side](rodin-party/game-1-face-side--1.png), [head turn](rodin-party/game-1-head-turn-1.png) |
| Ridge Wayfarer | [Full figure](rodin-party/ridge_wayfarer-front.png), [face](rodin-party/ridge_wayfarer-face.png) | [In game](rodin-party/game-2-idle.png), [axe](rodin-party/game-2-held-stone_axe.png), [bow](rodin-party/game-2-held-bow.png) |
| Ember Forager | [Full figure](rodin-party/ember_forager-front.png), [face](rodin-party/ember_forager-face.png) | [In game](rodin-party/game-3-idle.png), [axe](rodin-party/game-3-held-stone_axe.png), [walk](rodin-party/game-3-stride.png) |

## Preparation

- Each figure is grounded and normalized to a 2.06 m crown before the existing in-game avatar scale. Each has roughly 84,000–90,000 triangles, a 14-bone skin and at most four normalized influences per vertex.
- Colors are hand-authored surface selections on views of the actual sculpt. The illustration supplies the palette, not a projected image with baked shadows. Skin, hair, fabric, leather and metal have separate material roughness. Eyes, brows, lips, Ember's freckles and narrow garment edging are painted into the albedo.
- Each source UV layout is repacked from the shared eight-figure atlas to roughly 57–60% coverage of its own 2048×2048 albedo. Padding prevents black chart edges at distance. The export includes the texture; Godot's extracted PNG and import settings are checked in as well.
- Joint depths are measured inside the mesh with ray intersections. The Wayfarer's bent arm keeps its own measured rest pose. Surface-distance weights follow connected geometry rather than proximity through the air; cloth/gear masks, smooth transitions, lower-garment constraints and isolation of opposite arms limit hand/hip cross-influence. Small non-anatomical web faces between hanging hands and hips were cut; those contact seams still merit manual surface repair.
- Palm and finger skin receives rigid hand weights. Open fingers are separated into left/right skinned meshes, using the game's existing visibility controls when a held tool needs the closed grip. First-person and generated grip skin colors match the four new palettes.
- Willow's cape and Ridge's poncho receive soft secondary weights; packs and source gear primarily follow the torso. Existing movement, tool handling, inventory, combat, camera controls and save format 12 are unchanged.

## Review iterations

The first pass revealed muddy projection colors in the prior Willow, jagged vertex-painted boundaries, unused atlas space and a double sRGB conversion. The new texture bake corrected those. Native review then found arm weights pulling adjacent garments into spikes. Surface-distance weights, smoothing and protected lower garments replaced that approach. Dallon then identified Ranger’s displaced right jaw. Lower-face vertices were following the torso through the fused scarf. The face now follows the head rigidly, the neck gets the bending transition, and the scarf color is excluded from the side of the jaw. The source also had an oversized right under-ear/jaw lobe; a small feathered correction located with rays through the offending area, followed by local surface smoothing, reduces that bulge. Stronger reshapes were rejected because they folded the surface. The source face still has visible asymmetry and needs a dedicated sculpt/retopology pass. The regression also checks the Ranger jaw’s head binding; native reviews include both sides and head turns. The preview camera was also corrected to stop the chase camera from taking over and to place the feet above the ground. Blender's separate-scene library write crashed; the final editable artifact is one ordinary saved Blender scene containing all four rigs.

## Willow equipment follows inventory

Willow’s bow and arrow tips were fused into the original sculpt, so inventory visibility could not hide them. The rebuild now removes those surfaces and loose remnants, closes their attachment openings, and bakes the repaired areas into the existing 2K map. Her original download is unchanged. The ordinary inventory-driven bow and quiver remain: a fresh traveler has neither; crafting equips the usable bow; unequipping stows it; moving bow/arrows to a chest removes them. The bow lies flat behind the bag, and the carry mounts are fitted to Willow’s deeper authored outfit.

Actual Godot captures: [fresh back](rodin-party/willow-equipment-fresh-back.png), [fresh front](rodin-party/willow-equipment-fresh-front.png), [crafted and held](rodin-party/willow-equipment-held-front.png), [stowed bow/arrows](rodin-party/willow-equipment-crafted-back.png), [side clearance](rodin-party/willow-equipment-crafted-side.png), [equipment stored in a chest](rodin-party/willow-equipment-stored-back.png).

`willow_equipment_test.gd` checks that the fixed shoulder-bow geometry is absent, samples carry meshes against the rear clothing/bag envelope, and exercises real crafting and inventory-to-chest transfers. With `-- --screenshots` and graphics enabled it captures the states above. All 29 suites pass. Save data and recipes are unchanged.

## Remaining limits and useful next work

These remain prototype character skins. Rodin fused clothing, fingers and equipment into sculpted surfaces; tight sleeves, the hip/hand contact areas and Ridge's bent-arm poncho still compress or stretch in strong poses. Some painted boundaries around hidden sides and pack straps need finer manual cleanup. The eyes are painted onto the existing sculpt, with no moving eyeballs, blinking or facial rig. Willow’s sculpted bow and arrow tips have been removed; her travel bag remains part of the outfit. The other models’ sculpted pick and packs remain cosmetic, so gameplay equipment can overlap those. There is no cloth simulation or foot IK; the source stance has one heel slightly raised.

The best next art pass is to separate equipment, repair those contact surfaces and retopologize the shoulders/hands, then refine Willow's eye sockets and face texture at close range. A single neutral-pose character export from Rodin, without held tools or duplicate turnaround figures, would make future replacements substantially easier. New software is not required for the current pass.

## Rebuild and verify

- Source SHA-256: `4ef4cfaf1554696bbede3617f438fa8ac4cf10f9c9b948dd130d8b88f3a887f6`.
- Editable scene: `art/blender/rodin_party/travelers.blend`; albedos and per-character JSON reports alongside it. The older studies and Willow-only pipeline remain preserved.
- Blender 5.2.1: `Blender --background --factory-startup --python-exit-code 1 --python tools/blender/prepare_rodin_party.py -- /path/to/Travelers.glb`. `rodin_party_regions.py` holds source-specific selections, palettes and joint landmarks; `rodin_party_texture.py` bakes the maps; `rodin_party_weights.py` binds the skins. `render_rodin_party.py` renders the actual saved figures together.
- Godot 4.7.2: `Godot --headless --recovery-mode --import --path .`, then all 28 headless suites. The traveler suite now also requires the four 2K albedos and both separate finger meshes, alongside selection, persisted inventory, skeleton and movement/equipment checks. A separate deformation suite measures hip-triangle stretch under actual axe, bow, spear and walking bone transforms.
- Native `Godot --path . --script res://tests/rodin_travelers_preview.gd` captures faces, idle, axe/bow and stride views using temporary saves only. No real player saves were read or changed. Headless runs have the known macOS certificate warning; sandboxed editor imports also cannot save global editor settings. Neither prevented asset imports or the tests.
