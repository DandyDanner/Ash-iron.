# Approved character direction: Willow Scout

Dallon selected character 1, Willow Scout, from the four-character comparison. This replaces the earlier suggestion to start with Hearthland Ranger.

The original approved comparison is `approved-character-options.png`. The derived modeling reference is `willow-scout-turnaround.png`. These are concept illustrations. The playable first pass now uses original procedural shaped meshes and an articulated node rig, with walking, jumping, tool gestures, cape movement, and a collision-aware third-person camera. It is a simplified interpretation, not a finished production sculpt or a pixel match to the illustration.

Preserve the lean, agile build; expressive face; tousled dark hair; sage shoulder cape; cream rolled-sleeve shirt; teal sash; sand trousers; and folded-cuff brown boots. Use the back view to guide the third-person silhouette. Face, hair, skin, and body customization should remain possible. Equipment shown is a visual reference, not a decision to give new players free tools or ammunition.

The character creator and in-game body share the same model and customization. First person remains available with V, and previous saves keep their progress. Bow, quiver, arrows, and held tools appear only when owned. Next art milestone: refine face, hair, cape folds, and hand/tool contact from in-game feedback, then replace individual procedural parts with authored assets as needed.

## Generation provenance

Created with the built-in image-generation tool, using the approved four-character image as the reference. The generated source files remain unchanged in Codex's generated-images folder.

## Final generation prompt

Use case: identity-preserve / stylized-concept.
Create a polished character turnaround reference sheet based ONLY on character number 1, WILLOW SCOUT, in the supplied four-character comparison image. The user explicitly selected this design for the original Ash & Iron game.
Reference role: exact character identity, outfit, colors, proportions, and art style reference. Preserve the Willow Scout's warm tan skin, dark brown expressive eyes, tousled black-brown hair with short tied-back tuft, appealing youthful adult face and lean agile build. Preserve the green cropped hooded shoulder cape with cream tiny geometric border accents and brass clasp, cream rolled-sleeve button shirt, dark teal layered waist sash, asymmetrical brown leather straps and modest hip pouches, sand cropped trousers, exposed ankles, folded-cuff brown lace boots, simple wooden bow and modest quiver.
Make a NEW wide landscape modeling reference sheet with THREE full-height, equally scaled views of the SAME Willow Scout: exact FRONT view, exact SIDE profile, exact BACK view. Neutral standing pose with arms slightly away from body, hands relaxed; consistent head height, feet baseline, body proportions, garment construction and equipment across all three views. Keep the very same face and proportions seen in the original first panel. Normal rounded human ears. Bow and quiver worn on the back, coherent strap attachment; no extra armor, no new outfit, no redesign. Make the back cape and sash particularly clear for a third-person camera. Keep the front design uncluttered and the hands visible.
Style: same attractive stylized 3D-game concept look as the approved original, soft cel shading, broad readable shapes, restrained painterly texture, warm light and cool shadows. Matte materials, no photoreal skin or gritty realism, no chibi distortion. Plain warm ivory backdrop with generous margins; no environment, game UI, stat cards, other characters, or logos.
Text: title at top exactly "ASH & IRON — WILLOW SCOUT"; labels beneath the figures exactly "FRONT", "SIDE", "BACK". High-quality legible design sheet, full boots and hair visible, no crop. This is a visual reference illustration for later 3D modeling.

## Current rendered refinement

The September 10 character/boar-only pass adds higher resolution rounded surfaces and curved volumes while retaining the existing animation and gameplay interfaces. The scout has swept hair, defined facial features, cape embroidery, and a folded hood; the boar has curved tusks, muzzle details, and layered fur. The world is unchanged. These remain simplified procedural models, not final sculpts or textured matches to the illustrations.

`tests/art_portrait.gd` renders the actual geometry in a neutral studio and in the existing clearing, without reading or modifying the player's save. Use these actual renders for judging progress, rather than generating another concept image as evidence of game quality.
