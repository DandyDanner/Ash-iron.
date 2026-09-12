# Rodin traveler review — September 11

Historical Willow-only pass. The current four-model integration is documented in [the Rodin party review](RODIN_PARTY_REVIEW.md).

Dallon generated the Willow Scout with Rodin (Hyper3D) from her turnaround sheet. The download (`base.glb`: 500,000 triangles, no textures, no rig) holds three fused figures, the front, side and back views reconstructed as separate bodies. The front figure has the cleanest face and hands and a complete back, so it becomes the playable Willow. The download itself is not in the repository and stays unchanged.

## What the pipeline does

`Blender --background --factory-startup --python tools/blender/prepare_rodin_traveler.py -- /path/to/base.glb --figure=0` (Blender 5.2.1):

1. Welds the mesh, separates the connected figures, keeps the requested one (left to right), grounds it, centres it between the legs and scales it to 2.06 m at the crown.
2. Reduces 171,626 triangles to 90,000 with a collapse decimate and shades smooth.
3. Measures the figure's own joints from horizontal slices: hips and knees from the two largest leg blobs, hands and elbows from the outermost band of each side, the shoulder pivot 9 cm inside the shoulder silhouette. Joint heights stay on the reference points shared with the other travelers.
4. Builds the 14-bone `TravelerRig` at those points and assigns positional weights (four influences, normalised) with smooth blends at the hips, knees, shoulders, elbows and wrists. Bow, quiver and arrows follow the torso.
5. Colours the figure from the turnaround sheet it was generated from (`--sheet`, default `Willow Scout.png`): each of the three drawings is fitted to the mesh's silhouette by maximising overlap, every vertex samples the drawing it faces (front, side or back) through a small blur, and a torso-only correction bends the height map through the drawn sash, which Rodin placed about 10 cm lower on the body. Colours are stored as linear vertex colours; where no drawing covers a vertex, the Willow palette by region fills in. Materials are the shared `Game Fabric`, `Game Skin` and `Game Hair` set, so the runtime grain and lighting treatments apply.
6. Exports `assets/characters/willow_scout.glb` (about 3.9 MB), saves `art/blender/rodin_import/willow_scout.blend`, writes `willow_scout_report.json` beside it and renders the images below.

`scripts/authored_traveler.gd` now reads each export's bone rest positions for the joint pivots, so this figure keeps its own proportions. The three Blender travelers' bones sit exactly on the reference points (checked to 1e-7 m), so they animate as before.

## Actual renders

Cycles renders of the exported geometry with the matching review studio: [front](rodin-traveler/front.png), [back](rodin-traveler/back.png), [three-quarter](rodin-traveler/three-quarter.png), [face](rodin-traveler/face.png).

In-game captures from `tests/traveler_selection_test.gd -- --screenshots=...`: [character creator](rodin-traveler/game-creator.png), [axe grip in the clearing](rodin-traveler/game-axe.png), [bow held](rodin-traveler/game-bow.png).

## Measured pivots (metres, Godot Y-up, left side)

| Joint | Rodin figure | Shared reference |
|---|---|---|
| Hip | (-0.130, 1.094, 0.036) | (-0.114, 1.094, 0) |
| Knee | (-0.155, 0.616, 0.015) | (-0.114, 0.616, 0.008) |
| Shoulder | (-0.187, 1.644, -0.034) | (-0.172, 1.644, 0) |
| Elbow | (-0.284, 1.354, 0.022) | (-0.304, 1.354, 0.006) |
| Hand | (-0.352, 1.061, 0.100) | (-0.353, 1.061, 0.021) |

## Limitations

- Colours are a projection of a 2D illustration: its shading is baked in, thin features such as the chest strap and sash tails smear where the sculpt and the drawing differ by a centimetre or two, and the hair tint reaches onto the forehead. Rodin's own textured export of this generation would replace this with true textures; the `base_basic_pbr.glb` zip in Downloads belongs to the tree generation, not this one.
- Generated topology with no retopology; the decimate keeps the silhouette but not clean loops.
- One mesh: when a tool is gripped, the game's procedural closed fingers draw over the open sculpted hand. Splitting the fingers into their own mesh named with "Fingers" would let the existing hide/show logic work.
- The Cape bone carries no vertices, so the cape does not swing separately.
- The face has sculpted eyes without colour.

## Verification

All 24 headless suites pass after `Godot --headless --path . --import`. The traveler suite checks 14 bones, 14 binds, enabled vertex colours, walking, jumping, tool swings and the persisted world model for all four travelers. `Travelers.glb` in Downloads (all four travelers plus four small figures in one mesh) can go through the same script later with `--figure=N` for the other three.
