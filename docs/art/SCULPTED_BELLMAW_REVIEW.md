# Bellmaw sculpt, size and balance review — 2026-09-11

[Actual Godot attack motion](sculpted-bellmaw/motion.gif) · [New size beside the traveler](sculpted-bellmaw/size-after.png) · [Same mesh at the previous scale](sculpted-bellmaw/size-before.png)

These are native Godot captures, not concept art. The recording poses the actual skin through the attack states in place; gameplay and damage are exercised separately by the tests. The size comparison holds the camera and new mesh fixed while changing body scale from 2 to 4.

## Supplied model

The new `Bellmaw.glb` contains 500,000 triangles across three creatures and a backpack, combined in one mesh. It has UVs but no image textures, vertex colors, skin or animation. [Blender render of the original upload](sculpted-bellmaw/source-upload.png).

The largest connected creature is now the game mesh. It was reduced to 54,000 triangles (27,002 Blender vertices; export splits some for UV/normal boundaries), given olive/amber vertex colors and a 16-bone weighted skeleton. Its neutral height is normalized to approximately 1.34 m before the actor's 4× scale; in game it is approximately 5.36 m tall. The GLB is about 2.14 MiB. The original download was not edited.

- Editable source: `art/blender/bellmaw_sculpt/bellmaw.blend`
- Rebuild: `tools/blender/rig_sculpted_bellmaw.py -- /path/to/Bellmaw.glb` using Blender's `--python` invocation as documented in the script.
- Provenance, bounds, mesh counts and source SHA-256: `art/blender/bellmaw_sculpt/report.json`
- Current asset: `assets/creatures/bellmaw.glb`

Blender baseline clips are Idle, Walk, Warning and Recovery. Godot code drives the same bones for the full raised-paw slam, impact, exhausted recovery and mirrored paw swipe. Native review caught Godot importing the color array with its material flag disabled; the runtime enables vertex colors explicitly, and the rig test checks it.

## Playable balance on the Bellmaw branch

- Health: **300**, up from 160. Spear remains 20 during recovery, 10 through guarded hide: **15 optimal hits or 30 guarded hits**. Axe and arrow damage are unchanged.
- Size: actor scale **2 → 4**; capsule radius **1.32 → 2.64 m**, full length **5.4 → 10.8 m**. Obstacle probes and health-label height follow the scale.
- Slam: existing **6 m** ring, **34 damage**, **1.2 s** warning and **1.25 s** recovery. Both paws lift and impact with dust; rear support stays anchored in body space.
- Swipe: **7.6 m** radius to follow the larger paw reach, with an identical mirrored ground sector. Existing **0.85 s** warning, **18 damage**, one contact **0.12 s** into a **0.24 s** swing, **1.05 s** recovery, **5 s** cooldown and required preceding slam remain.
- Saves: format **12** scales old living Bellmaw health by percentage from the old 80/160 caps; zero stays zero, respawn time persists, and later reloads do not scale again. No player save was accessed for development or review.

## Verification and remaining polish

All 26 headless suites pass. Tests exercise skin weights/colors, actual weapon collision in both views, reach and cover, warned damage/dodging/pause, respawn clearance, 15/30-hit defeats and old-save migrations through subsequent save/reload. Native Godot screenshots and a 102-frame recording verify the imported mesh and pose/color behavior. The known headless macOS certificate lookup warning persists; native preview completed without errors.

The generated surface is smoother and more coherent than the previous mesh, but the color pass is basic. Eyes, claws and skin still need deliberate texture/detail work. Skin weights are an initial spatial blend rather than manual retopology/weight painting; shoulder deformation can stretch. Supporting feet are anchored relative to the body, not terrain-aware IK, and paws can intersect nearby props. The body capsule is approximate; the swipe uses the visible sector and cover query, not individual claw colliders. These are remaining polish limits, not finished cinematic animation.

The work was developed in a separate checkout and integrated with the committed RodinBridge handoff, preserving its addon/project configuration. Traveler/boar/world art and the original downloads remain untouched.
