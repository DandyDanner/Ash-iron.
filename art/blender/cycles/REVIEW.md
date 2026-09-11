# Eight-model Blender review cycles

These are actual Blender meshes and Cycles renders, generated locally from `tools/blender/model_characters.py`. They are **unrigged modeling studies**, not finished game assets. No runtime scene, world art, damage value, save format, or customization behavior changes in this work.

Dallon expanded the scope to Willow Scout, Hearthland Ranger, Ridge Wayfarer, Ember Forager, Bristleback Boar, Woodland Hog, Ridgeback Boar, and Meadow Buck. The three approved concept sheets are packed into each native file. The bear is deferred.

## Cycle 1 — build and inspect

Saved `cycle_01/characters.blend`, with actual front traveler/wildlife lineups and a scout face render. Built separate outfit/hair studies, accessories, continuous remeshed faces and animal bodies, cloth forms, boar fur, and deer anatomy.

Review: protruding cheek volumes and eyes made the faces look like toys; hair repeated identical clumps. Subdivision collapsed collar/jacket/ear boundaries and deer leg endpoints. Boots floated over the floor. Cloth was inflated; embroidery curved into arches; boar guard hairs looked like quills. This was not an acceptable illustration match.

## Cycle 2 — geometry corrections and inspect

Saved `cycle_02/characters.blend` and the same three camera views. Removed added cheek volumes, reduced nose/eye/ear projection, stabilized thin mesh boundaries and tube endpoints, narrowed sleeves, increased visible cloth folds, made embroidery corners angular, lowered models to the floor, and shortened/thinned/laid down boar fur.

Review: feet and deer leg connections improved, and faces stopped having separate cheek balls. Remaining faults included shoulder/cape overlap, uniform swept hair, the forager's bob covering her eyes, excessively rumpled trousers, and hard-edged cream throat markings on the deer. The face still read as a simplified doll rather than the approved illustration.

## Cycle 3 — silhouette/material corrections

Changes driven by the second review: varied and flattened swept hair locks, opened the forager's bob away from her eyes, widened the upper cape to cover shoulders, extended the ranger's jacket and colored its upper sleeves, reduced exaggerated trouser folds, softened the deer's throat boundary with an interpolated mesh attribute, reduced boar shoulder width and added swept mane clumps. Added rear traveler and side wildlife renders for accessory/anatomy review.

Review: the front view revealed remaining sleeve/cape intersections and hair fins caused by the orientation of flattened cross sections. Rear views showed underdeveloped hair at the back and plain packs. The side wildlife camera overlapped creatures, and mane clumps floated above the boar back. The deer's neck still showed joined rounded lobes. Corrected these in an additional pass rather than treating the third pass as finished.

## Cycle 4 — follow-up corrections

Reoriented flattened hair across the scalp, added back hair coverage, reshaped cape clearance and lowered sleeve shoulders, preserved broad strap boundaries, added pack flaps/stitches/buckles, anchored varied mane clumps to the actual boar surface, and replaced two deer neck volumes with a continuous tapered form. Spread side-profile animals farther apart for inspection.

Reviewed all five actual renders and opened the final native file in Blender. The front capes now cover sleeves; the forager's eyes remain visible; hair cross sections lie across the scalp rather than standing as fins. Rear views show pack closures, basket/herbs, quiver and bow. Side animals no longer overlap; deer neck lobes and the floating boar mane were corrected.

Remaining visual limitations are visible and should drive the next art review: faces and head shapes remain too similar and doll-like, hair still resembles layered shells, capes are stiff and broad, scarf/boot forms are simplified, the boar mane reads as repeated curved clumps, and animal anatomy needs more natural transitions. These are improved studies, not an illustration-quality or production-ready milestone. No animated clearance or runtime performance claim is made.

The final lineup is open in Blender. Native-file verification reopened all four versions: each contains all eight non-hidden model collections, all three packed references, and the expected render files. All fourteen gameplay suites passed with no runtime changes (the sandbox prevented default log-file writes; PASS output and test save paths were unaffected).

## Reproduce

Use Blender 5.2.1 LTS from the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/blender/model_characters.py -- --art-pass=5
```

A new pass number preserves existing `.blend` files; the generator refuses to overwrite a saved pass. Passes 4 and above use the latest geometry. A future iteration should change the source based on an actual render review before claiming another improvement. Cycle 1/2 snapshots preserve their exact meshes; later source maintenance is not a byte-identical reproduction guarantee.

Each design is in its own named collection. `APPROVED REFERENCES` holds packed images. `STUDIO — never export` is only a presentation setup. `REVIEW STATUS` inside the file states the modeling stage. This whole directory is excluded from Godot by its parent's `.gdignore`.

## Remaining work before game integration

The models need further face/hair/anatomy and garment shaping against the illustrations, retopology, UVs and baked game materials, a deforming skeleton and skin weights, animation and equipment-contact checks, customization mapping, and a tested import. Dense fur curves and Blender procedural shaders are study materials and will need a game-suitable conversion. This work does not certify concept fidelity, animated cloth clearance, or runtime performance.
