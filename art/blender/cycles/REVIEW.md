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

At the end of the garment pass, the continuation source was `cycle_15/characters.blend`, ready for animal refinement. Reproduce this garment checkpoint in a fresh output directory with `Blender --background --factory-startup --python tools/blender/refine_traveler_clothing.py -- --art-pass=99 --refinement=3`; this intentionally reads cycle 12 and must not overwrite later animal/model changes.

## Cycles 16–17 — wildlife anatomy and surface review

Loaded cycle 15 and rebuilt the four animals while retaining all four travelers. Cycle 16 uses continuous tapered trunks/heads, angled legs, cupped ears, cloven hooves, curved tusks and antlers, and surface-sampled coats. Each saved source has a wildlife lineup and four portrait/side pairs.

The first actual review exposed projecting bead eyes, arch-shaped thick mane locks, exposed leg-to-hoof gaps and abrupt shoulder/neck joins. The hog muzzle was too long and its mottling too harsh. Some side cameras clipped the snout or the buck's antlers/feet.

Cycle 17 replaces the projecting eyeballs with almond patches fitted to the head surface, thins the coat fibers, replaces the arch locks with dense swept tapered mane fibers, extends hooves to the lower legs and shortens the hog muzzle. Reviewing its nine renders confirms better eye contact and mane silhouettes; the block-shaped hooves, stiff ear shells and abrupt body joins remain. Softening the hog pattern went too far and largely lost the visible mottling. These are intermediate studies, not approved illustration matches.

Native verification reopened both sources: all eight model collections visible, three references packed, and 1,186 traveler objects retained identical geometry, transforms and material assignments. Earlier sources remain available.

## Cycle 18 — anatomy joins, hoof shape and silhouette correction

Moved limb starts into the body mass, increased cross-section resolution, softened the fused joins and rebuilt the buck neck from a deeper chest origin. Hooves now have tapered coronets and broader split toes instead of boxes. Added fine directional deer coat fibers and a downward tail, enlarged the fitted eyes, shortened the boar snouts and restored moderate hog mottling. Wider side framing shows complete silhouettes.

Reviewed all nine actual renders. The buck neck and shoulder attachments are smoother, lower legs meet shaped hooves, and the restored hog pattern is visible. Added cheek volumes, however, introduced an unacceptable inflated cheek/lower-jaw shape on all three pig/boar faces. This is explicitly retained as an intermediate fault to correct. The hoof material is still too uniformly dark/glossy and the animals remain simplified, symmetrical studies. Native verification confirmed all eight models/references and 1,186 unchanged traveler objects.

## Cycle 19 — cheek correction and recessed nostrils

Removed the inflated cheek volumes from cycle 18 while retaining the improved limb/neck joins, tapered hooves, fitted eyes, fur and shorter muzzles. Cut actual cavities into the pig/boar snout pads and placed dark surfaces behind the openings. Saved all nine ordinary views plus a rear lineup and four face details, and inspected them against the approved wildlife sheet.

The cheek regression is gone and the nostrils now have depth. The close views exposed fur strands crossing the eye surface and a small visible gap beneath the buck's antler bases; the rear view also shows how similar the two boar body shapes still are. The nose pads remain too simple, the ears resemble stiff shells, the eyelids look like trim around black patches, the deer face is still smooth and plain, and dense fine fibers do not reproduce the reference's varied fur clumps. These studies remain substantially below the illustrated target. Native verification confirms all eight models, three references and 1,186 unchanged traveler objects.

## Cycle 20 — attachment and eye-clearance cleanup

Loaded the saved cycle 19 source directly. Seated the buck's antler bases and ears into the head, removed 323 coat strands that crossed or crowded the pig/boar eye patches, and gave all hooves a softer matte brown horn material. Re-rendered full silhouettes, portraits, sides, the rear lineup and four face details. The close-ups confirm the visible antler gap is closed and the stray fibers no longer cross the eye surfaces. The antler/ear bases still need anatomical blending rather than simple intersections; this is contact correction, not finished anatomy.

Across cycles 16–20, inspected 55 actual Blender images. Reopened all five native sources and verified eight visible model collections, three packed references, finite animal body vertices and 1,186 traveler objects with identical geometry, transforms and material assignments. All fourteen gameplay suites passed with exit 0. The world, game code, balance, saves and playable characters remain unchanged.

**Continue from `cycle_20/characters.blend`.** The animals now have more continuous anatomy, fitted eyes, fine coats and shaped hooves, but remain substantially below the illustration target. The two boars share too much of one body silhouette, the eye rims look applied, ears and snout pads are stiff/simple, and fur needs broader varied clumps and directional color changes. The buck needs more natural facial planes, muzzle/ear/antler transitions, lower-leg landmarks and coat markings. These are dense unrigged studies requiring topology, UVs/material baking, skinning and game import work before use.

Next return to traveler face/ear and garment-contact refinement, preserving this animal checkpoint. To reproduce the attachment correction in a fresh folder, use `Blender --background --factory-startup --python tools/blender/polish_wildlife_attachments.py -- --art-pass=99`; it intentionally reads cycle 19. To reproduce the preceding animal reconstruction, use `refine_wildlife.py -- --art-pass=99 --refinement=4`; that intentionally reads cycle 15. Never use these baseline-specific scripts to overwrite later edits. `render_wildlife_details.py -- --art-pass=20` renders the latest rear/face inspection images without altering the saved source.


## Cycles 21–22 — eyelids, ears and facial expression

Loaded cycle 20 and retained its complete animal work. Sculpted small socket/cheek/nose adjustments into the existing continuous traveler heads, narrowed the lower jaws more for scout/forager, rebuilt smaller fitted almond eyes with skin eyelid bands, and replaced thin ear panels with closed cupped volumes, helix and inner folds. Each pass has front/rear lineups and front/profile closeups of all four faces.

Cycle 21 review showed more ear depth and less exposed eye white, but lips still projected sharply and the lower jaw remained too horizontal. The ranger's stubble was coarse and sparse, while the forager's pale freckles resembled raised marks. Cycle 22 slopes the underside of each jaw, refits lips and the mouth line to the face, seats warmer freckles, and replaces individual coarse beard strokes with finer surface-following fibers.

All 20 actual images were inspected. The jaw/lip profiles are more connected and the freckles read more clearly. The new beard, however, has sharply bounded cheek/mouth regions, addressed in cycle 24. Faces still look generic and smooth; eyes/ear folds retain an applied-rim appearance, nostrils remain surface strokes, and hair is broad repeated sculpted locks. These changes do not establish illustration fidelity. Both native files reopened with all eight models/three packed references and 856 unrelated objects retaining identical geometry, transforms and material assignments.

## Cycles 23–24 — hanging capes, garment contact and stubble boundaries

Loaded cycle 22 and narrowed the scout/wayfarer cape silhouettes, changed the shoulder-to-hem drop, retained sleeve clearance, rebuilt borders/embroidery on those surfaces, and fitted their straps to the underlying cape, shirt and sash. Cycle 23 review exposed pieces of the old shirt collars piercing the narrower cloth, along with a remaining ochre shirt patch beneath the wayfarer cape. The capes remain stiff overall, and the side view still shows strap bridging.

Cycle 24 removes the two covered collars per cape, eases strap depth changes, moves buckle leather into view and grades the ranger beard's upper/side/mouth boundaries with varied fiber density. Reviewed all seven cycle 23 images and all nine cycle 24 images, including ranger front/profile details. The collar triangles are gone and the beard no longer ends in a sharp rectangle; one upper-shirt patch still pierces the poncho and requires a surface-clearance correction. The ranger jacket and forager collar remain stiff, the scout's sash creates repeated strap ripples, and equipment is still simplified and not motion-tested. Keep these intermediate images as the record of defects, not as approved final art.

Cycle 23 native verification retained all eight models/packed references and 914 objects outside the cape/strap scope. Cycle 24 additionally changes the covered collars and ranger beard; native verification retained 909 objects outside that scope with identical geometry, transforms and material assignments.



## Cycles 25–26 — fitted braids and final cloth clearance

Loaded cycle 24. Replaced the wayfarer's seven elevated crown rows with eleven narrower braids fitted to the evaluated scalp, plus nine curved trailing paths starting from the crown ends. The close front/profile views show a rounder silhouette following the head; the hairline foundation remains visibly cap-like and the repeated braid pattern is still too uniform. Cycle 25 rear review caught small gaps at the crown-to-trailing joins. Cycle 26 embeds the crown centers slightly more and overlaps the hanging braid roots, closing those visible gaps. The root shapes still need natural blending and varied transition widths.

Also checked both capes against the evaluated shirts, moved penetrating cape regions outside the underlying cloth, and kept strap surfaces above the revised capes. The wayfarer upper-shirt patch is gone in the corrected outfit view. These are static clearance fixes; the scout strap still bridges the cape edge and follows the sash too mechanically.

Each pass contains eight actual renders: traveler front/rear lineups, wayfarer front/profile/rear closeups, scout/wayfarer outfit views and scout side view. All 52 pass images from cycles 21–26 were inspected, followed by an additional all-eight overview rendered directly from the final saved source. Reopened cycles 25/26 and verified eight visible collections, three packed references and 888 objects outside the braid/cape scope with identical geometry, transforms and material assignments. All six sources in the final overnight session preserve the complete animal checkpoint from cycle 20. No world, runtime, balance, save, or playable-model changes. All fourteen gameplay suites passed with exit 0; sandboxed Godot also reported its previously seen system certificate lookup warning.

**Continue from `cycle_26/characters.blend`.** The complete set remains substantially below the approved illustrations. Next, give Willow Scout a focused silhouette/face/hair/garment sculpt pass rather than spreading small details across the set. The animals retain the cycle 20 limitations described above. Retopology, UVs/baked materials, deforming rigs/weights and tested game integration remain future work.

Reproduce the last face checkpoint from cycle 20 using `refine_traveler_expression.py -- --art-pass=99 --refinement=2`; reproduce the cape/stubble checkpoint from cycle 22 using `refine_cape_silhouettes.py -- --art-pass=99 --refinement=5`; reproduce the final braid/clearance correction from cycle 24 using `fit_wayfarer_braids.py -- --art-pass=99 --refinement=3`. Prefix with `Blender --background --factory-startup --python tools/blender/`, use unused pass numbers, and never overwrite newer manual work with these baseline-specific scripts.


## Reproduce

Use Blender 5.2.1 LTS from the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/blender/model_characters.py -- --art-pass=99
```

A new pass number preserves existing `.blend` files; the generator refuses to overwrite a saved pass. The old full-set generator reproduces the cycle 4 design; it does not include later face, hair, garment or animal work. A future iteration should change the source based on an actual render review before claiming another improvement. Cycle 1/2 snapshots preserve their exact meshes; later source maintenance is not a byte-identical reproduction guarantee.

Each design is in its own named collection. `APPROVED REFERENCES` holds packed images. `STUDIO — never export` is only a presentation setup. `REVIEW STATUS` inside the file states the modeling stage. This whole directory is excluded from Godot by its parent's `.gdignore`.

To reproduce the face milestone in a new output directory, run `Blender --background --factory-startup --python tools/blender/refine_traveler_faces.py -- --art-pass=99 --refinement=2`. This intentionally reads cycle 4 and applies the face reconstruction, so do not use it to overwrite later hair/clothing changes.

## Remaining work before game integration

The models need further face/hair/anatomy and garment shaping against the illustrations, retopology, UVs and baked game materials, a deforming skeleton and skin weights, animation and equipment-contact checks, customization mapping, and a tested import. Dense fur curves and Blender procedural shaders are study materials and will need a game-suitable conversion. This work does not certify concept fidelity, animated cloth clearance, or runtime performance.
