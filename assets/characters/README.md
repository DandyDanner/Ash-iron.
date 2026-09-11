# Playable traveler exports

Willow Scout is exported from `art/blender/cycles/cycle_30/characters.blend`; the other three original models remain exported from the preserved `art/blender/cycles/cycle_26/characters.blend` and selected through the creator's Traveler menu. Wildlife remains in the source studies.

Rebuild from the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/blender/export_playable_travelers.py
```

Add `-- --design=willow_scout` to rebuild only Willow. The exporter reopens the recorded source for each character and never saves it. It reduces subdivision/curve resolution, decimates dense pieces, bakes source colors into COLOR_0, preserves separate cloth/skin/hair/brass/eye materials, and exports a 14-bone skin. `export_report.json` records source, size and geometry counts. No reference images or source studio lights/cameras enter the game.

`authored_traveler.gd` maps those bones to the existing movement and equipment controls. Separate open-finger meshes hide when tools use the existing closed grip. Decorative source bows, quivers and arrows are excluded; gear visibility follows the player's inventory.

This is a first playable integration, not finished production character art. Geometry remains dense (roughly 210–355k triangles per traveler), capes use a simple bone, and elbow/knee deformation needs continued visual refinement. There is no foot IK, cloth simulation, facial animation or baked detail/LOD system. Models retain the source studies' simplified anatomy and clothes. The original customized scout stays available as a separate menu choice.

Actual Godot creator captures: [Willow Scout](../../docs/art/playable-travelers/willow-scout.png), [Hearthland Ranger](../../docs/art/playable-travelers/hearthland-ranger.png), [Ridge Wayfarer](../../docs/art/playable-travelers/ridge-wayfarer.png), [Ember Forager](../../docs/art/playable-travelers/ember-forager.png).

Willow’s focused facial pass has a reshaped jaw/nose/mouth, rounded eye surfaces with colored irises, shaped lids, and flatter swept hair with restrained strand detail. Matched Blender renders and limitations are in [the focused review](../../docs/art/WILLOW_FOCUSED_REVIEW.md). The world, other playable travelers and gameplay rig remain unchanged.
