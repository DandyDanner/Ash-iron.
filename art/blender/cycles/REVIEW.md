# Eight-model Blender review cycles

These are actual Blender meshes and Cycles renders, authored locally with the versioned workflows under `tools/blender/`. They are **unrigged modeling studies**, not finished game assets. No runtime scene, world art, damage value, save format, or customization behavior changes in this work.

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

## Cycles 5–6 — overnight facial reconstruction

Loaded `cycle_04/characters.blend` and rebuilt only the four travelers' facial geometry. The saved source is preserved; no regeneration of outfits, hair, body, or animals. New surfaces give the ranger/wayfarer broader jaws, the scout/forager shorter lower faces, continuous nasal/cheek planes, fitted almond-shaped visible eyes, larger irises, shaped lip surfaces, folded ears, and surface-following beard/freckles. Rendered the full traveler lineup, individual closeups of all four faces, and the scout's profile.

Cycle 5 review found a black-ear/eyelid material error (the cheek-tint vertex attribute was missing on those objects), a visible chin crease from uneven interpolation of profile rings, and overly narrow eyes. Cycle 6 corrects the shared material, uses slopes measured along the profile for smoother curvature, broadens the lower jaw, and increases iris/eye height. Reviewed all four corrected portraits and the scout profile: the ear color and jaw crease are corrected; profiles still show a simplified ear and ocular region. Native-file verification confirmed all eight models and packed references, with 892 unrelated objects retaining identical geometry, transforms, and material assignments in both facial passes.

Still unresolved: the eyes remain stylized fitted patches with limited depth rather than a complete ocular socket, lips are simple, faces need more individual personality and asymmetry, and the illustrated expression is not yet matched. Existing shell-like hair and rigid garments are now especially visible beside the revised face. No illustration-fidelity or game-readiness claim. Cycle 5 is retained as a review record of faults, not the preferred model.

At the end of the face pass, the continuation source was `cycle_06/characters.blend`. Next priority: authored hair coverage and flowing clumps, then tailored/draped outfits and distinct silhouettes; subsequent animal refinement must retain these faces. Do not run the old full-set generator and accidentally discard the facial work.

## Cycles 7–8 — overnight hairstyle reconstruction

Loaded the saved cycle 6 scene and replaced only the four travelers' hair. Authored a continuous scalp foundation, overlapping curved locks with directional surface strands, a tied-back scout cut, swept ranger waves, a copper bob, and closed woven braids. Both passes include front/rear lineups, four face portraits, and a scout profile. All animals and the previously revised faces are retained.

Cycle 7 review found antenna-like scout wisps, three handle-like loops above the forager's bob, a sparse flat hairline below the wayfarer's braids, glossy locks, and repeated pointed bob ends. Cycle 8 shortens and lowers the scout's wisps, reduces the forager's top accent to one low asymmetric wave, curves broader bob ends inward, lowers the crown braids to the hairline and closer to the skull, varies trailing braid lengths, and reduces hair gloss. The braid strands now cross in a figure-eight pattern rather than following a simple three-strand helix.

The scout profile also exposes an unresolved facial issue from cycle 6: the transition below the projecting nose recedes too abruptly toward the upper lip, and the mouth/chin profile is too simple. This pass preserves the face so that issue is still present. It needs correction before treating the face milestone as approved. The ranger beard is sparse repeated strokes; braids and back hair still repeat too regularly; the face lacks the expression and asymmetry of the reference. Clothing remains rigid. These studies are still substantially simpler than the illustrations.

Reviewed all seven actual renders in each hair pass. The corrected braids reach the forehead, though the exposed side foundation and very regular braid rows still read as a stylized cap. Reopened both native files and verified all eight visible model collections, three packed references, and 1,194 unchanged non-hair objects (geometry, transforms, material assignments). All fourteen gameplay suites passed with exit 0. No runtime changes.

At the end of the hair pass, the continuation source was `cycle_08/characters.blend`. Next: correct facial profiles while preserving the new hair, then improve garment drape and distinct silhouettes; refine animal anatomy/fur afterward. Both old generators read earlier baselines and must not discard newer work. To reproduce the hair pass in a fresh directory: `Blender --background --factory-startup --python tools/blender/refine_traveler_hair.py -- --art-pass=99 --refinement=2` (intentionally reads cycle 6).

## Cycles 9–12 — overnight profile reconstruction

Loaded cycle 8 and reshaped the four saved facial surfaces plus their attached eyelids, lips, nostrils, freckles and beard strands. New hair, garments and animals are preserved. Each version includes a full traveler lineup and front/side portraits of all four travelers, so the side-view faults are recorded explicitly.

Cycle 9 softened the isolated nose peak, filled the upper-lip region and shortened the lower face (more for scout/forager). Actual profile review showed a receding chin and a hollow beneath the lip. Cycle 10 broadened the chin and raised the mouth, but the separate local adjustments introduced an obvious pinched philtrum above the lips. These are retained as intermediate review records, not approved profiles.

Cycle 11 replaces those local offsets with a continuous authored nose–lip–chin silhouette, smoothly interpolated without overshoot and blended across the cheek surface. Attached features follow the same surface adjustment. The scout side view lost the deep pinch, but the front portraits exposed an overly broad nasal-to-cheek blend, particularly on the wayfarer. Cycle 12 narrows that influence around the nose while retaining the broader chin transition.

Reviewed all 36 actual renders across the four profile passes. Cycle 12 retains a continuous side silhouette with reduced nasal side bulges. Remaining limitations: the facial planes and expressions are still simplified and too similar; the chin has a noticeable planar shading transition, nostrils are surface strokes, ears are thin folded shells in side view, and the eyes still lack full socket depth. The forager profile is partly obscured by her bob. This is a structural correction, not a fidelity approval.

Native verification reopened all four files: all eight visible model collections, all three packed references, finite face vertices, and 890 non-face objects retained identical geometry, transforms, and material assignments. All fourteen gameplay suites passed with exit 0. No world, gameplay, balance, save, or playable model changes.

At the end of the profile pass, the continuation source was `cycle_12/characters.blend`. Next is a substantial garment pass: sloping cape shoulders and natural folds, shaped jacket/sleeve joins, gathered cuffs/scarves, and equipment clearance. Preserve current faces/hair. To reproduce the profile checkpoint in a fresh folder: `Blender --background --factory-startup --python tools/blender/refine_traveler_profiles.py -- --art-pass=99 --refinement=4`; it intentionally reads cycle 8 and therefore must not overwrite later clothing work.

## Cycles 13–15 — overnight garment reconstruction

Loaded cycle 12 and rebuilt all four travelers' sleeves/cuffs, the scout's cape and teal sash, the wayfarer's closed poncho, both scarves and the ranger jacket. Facial profiles, hair, bodies and animals remain intact. Each saved pass includes front/rear lineups, four outfit closeups and a scout side view.

Cycle 13 replaces the flat cape shoulders with a sloping silhouette, adds fuller gathered sleeves and rolled fabric cuffs, a longer closed poncho with woven borders, and shaped jacket panels/lapels. The review caught buried straps/scarf, the scout sash intersecting a pouch, a visible wrap seam, jacket back coverage gaps, and capes that still resembled stiff domes.

Cycle 14 increases cape folds, reduces front/back depth, raises and broadens scarves, reconstructs the ranger's jacket back, draws sleeve starts farther into the shoulder, gives the forager cream cuff linings, and moves the sash tail behind the pouch. Rebuilt the cape straps to follow the actual cloth surface. The closeups then exposed ochre sleeve patches through the poncho and abrupt strap bends at the cape edge; the sash wrap also had a non-periodic fold phase.

Cycle 15 adds clearance around the sleeve volumes, eases the strap depth transition across cape edges, moves strap stitches above the leather surface, and makes the sash fold phase periodic. These are static model corrections; there is no animated cloth or equipment-clearance approval.

Reviewed all 21 actual images from the three garment passes. The final front/three-quarter views no longer show the ochre sleeve patches through the poncho or sash through the pouch; the scarf and stitched straps are visible and the sash seam is corrected. Remaining issues are visible: capes still have a stiff overall shape, shoulder joins and shirt collars need a more integrated construction, the scarf/sash folds repeat too regularly, and the scout side view shows the strap standing away from the chest as it bridges the cape edge. The strap/buckle stitching also needs contact cleanup. This remains an offline study, well short of the illustrated cloth detail or animated fit.

Reopened all three native files and verified all eight visible model collections, all three packed references, and 1,292 non-garment objects with identical geometry, transforms and material assignments. Fourteen gameplay suites passed with exit 0. No runtime/world/save/balance changes.

**Continue from `cycle_15/characters.blend`.** Next pass should refine animals while retaining the complete traveler work. Reproduce this garment checkpoint in a fresh output directory with `Blender --background --factory-startup --python tools/blender/refine_traveler_clothing.py -- --art-pass=99 --refinement=3`; this intentionally reads cycle 12 and must not overwrite later animal/model changes.

## Reproduce

Use Blender 5.2.1 LTS from the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/blender/model_characters.py -- --art-pass=99
```

A new pass number preserves existing `.blend` files; the generator refuses to overwrite a saved pass. The old full-set generator reproduces the cycle 4 design; it does not include later facial work. A future iteration should change the source based on an actual render review before claiming another improvement. Cycle 1/2 snapshots preserve their exact meshes; later source maintenance is not a byte-identical reproduction guarantee.

Each design is in its own named collection. `APPROVED REFERENCES` holds packed images. `STUDIO — never export` is only a presentation setup. `REVIEW STATUS` inside the file states the modeling stage. This whole directory is excluded from Godot by its parent's `.gdignore`.

To reproduce the face milestone in a new output directory, run `Blender --background --factory-startup --python tools/blender/refine_traveler_faces.py -- --art-pass=99 --refinement=2`. This intentionally reads cycle 4 and applies the face reconstruction, so do not use it to overwrite later hair/clothing changes.

## Remaining work before game integration

The models need further face/hair/anatomy and garment shaping against the illustrations, retopology, UVs and baked game materials, a deforming skeleton and skin weights, animation and equipment-contact checks, customization mapping, and a tested import. Dense fur curves and Blender procedural shaders are study materials and will need a game-suitable conversion. This work does not certify concept fidelity, animated cloth clearance, or runtime performance.
