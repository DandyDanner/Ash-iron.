# Willow Scout — focused face and hair review

The target remains the [approved Willow Scout sheet](willow-scout-turnaround.png). This pass focuses on the actual head geometry and its game export. All images below are native Blender renders of the saved models; the before and after use identical cameras, framing and lighting. They are not generated concept images.

## Matched comparisons

| View | Previous model (cycle 26) | Current model (cycle 30) |
| --- | --- | --- |
| Front | [Before](../../art/blender/cycles/cycle_30/before-front.png) | [After](../../art/blender/cycles/cycle_30/after-front.png) |
| Three-quarter | [Before](../../art/blender/cycles/cycle_30/before-three-quarter.png) | [After](../../art/blender/cycles/cycle_30/after-three-quarter.png) |
| Profile | [Before](../../art/blender/cycles/cycle_30/before-side.png) | [After](../../art/blender/cycles/cycle_30/after-side.png) |
| Whole character | [Before](../../art/blender/cycles/cycle_30/before-full.png) | [After](../../art/blender/cycles/cycle_30/after-full.png) |

Native Godot checks: [creator](willow-focused/creator.png), [Face / outfit closeup](willow-focused/creator-close.png), [studio portrait](willow-focused/willow-face.png), [clearing](willow-focused/willow-in-clearing.png). Game lighting and materials differ from the Blender studio; these captures show the actual exported result.

## Revisions and findings

1. **Cycle 27:** rebuilt the continuous face with cheek/socket/bridge/philtrum/chin shaping; shaped lips and brows; replaced flat eye patches with rounded surfaces and colored iris detail; rebuilt swept fringe and tied hair. Review exposed excessive eye projection, an overly sharp nose/jaw profile and large loop-like hair clumps.
2. **Cycle 28:** reduced nose projection, brought the mouth/chin profile forward, flattened the fringe, reduced loose hair loops and softened hair roughness/detail. Review exposed facial geometry overlapping the inner eye surfaces. Removing all strand detail made the hair too smooth.
3. **Cycle 29:** fixed eye-surface clearance, adjusted iris/opening proportions and restored much finer, lower-contrast strand detail. The side review still showed a hard bottom edge at the chin.
4. **Cycle 30:** rounded the bottom chin transition and retained the reviewed eye and hair corrections.

## What remains

This is an incremental improvement in facial definition and eye depth, not a finished illustration match. Hair still reads as sculpted clumps with a visible underlying cap; the ear construction is simplified. Facial expression and anatomical transitions need more art work. The torso, cape, sleeves, hands and boots retain their earlier prototype shapes and are a large part of the remaining toy-like appearance. There is no facial animation, skin microtexture or cloth simulation.

Judge the actual front, side and whole-body renders together. More tiny details alone will not solve silhouette and garment construction. Keep the focus on Willow until the overall character is convincing; do not propagate a claimed quality milestone to the other travelers.

## Preservation and reproduction

Each saved cycle includes all eight source studies. `verification.json` records the same geometry/transform/material-assignment fingerprint for the other seven models (771 objects). The three other playable GLBs and clearing scene are checked separately against their pre-session SHA-256 hashes. The original sources remain preserved.

From the repository root, a fresh output number can reproduce the final variant:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/blender/refine_willow_scout.py -- --art-pass=31 --revision=4
```

The script refuses to overwrite a saved cycle. Revision 4 rebuilds the focused changes over cycle 26 and copies the fixed baseline renders from cycle 27. The game exporter records per-character source versions and supports exporting only Willow.
