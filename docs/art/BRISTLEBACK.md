# Bristleback Boar

Dallon approved creature #1 on the original [wildlife concept sheet](first-wildlife-concepts.png) as the first playable enemy.

## Art direction

A compact russet boar with a heavy shoulder silhouette, darker raised mane, tapered snout, small amber eyes, cloven hooves, and curved ivory tusks. Keep its shapes readable against the grass and its expressions approachable but territorial. The current model uses original shaped meshes and articulated nodes; a finished sculpt, textures, skeletal animation, and audio remain future work.

## First encounter

Home is in the back-left grove at (-15, 0.22, -13). Approach → one-second lowered-head warning and pawing → committed straight charge → 1.6-second recovery. The player can sidestep and counter with the spear or bow. Obstacles stop charges; leaving the territory lets it return home and recover. The starting camp is safe.

60 boar health; spear hits deal 20 and arrows 25. Each charge deals 25 to the traveler’s 100 health. Defeating the boar yields one collectible hide and persists across saves; no respawn or hide recipe yet. Traveler defeat returns to camp with belongings intact. Resting near the original spawn heals gradually after eight seconds without damage.

## Approved later progression

1. Bristleback Boar — first readable combat encounter, implemented.
2. Woodland Hog — later variation.
3. Ridgeback Boar — larger, tougher encounter later.
4. Meadow Buck — deer and fleeing wildlife later.

A bear comes later still. Ore and smelting are the next crafting milestone; the other creatures are not implemented yet.

## Current rendered refinement

The September 10 character/boar-only pass adds higher resolution rounded surfaces and curved volumes while retaining the existing animation and gameplay interfaces. The scout has swept hair, defined facial features, cape embroidery, and a folded hood; the boar has curved tusks, muzzle details, and layered fur. The world is unchanged. These remain simplified procedural models, not final sculpts or textured matches to the illustrations.

`tests/art_portrait.gd` renders the actual geometry in a neutral studio and in the existing clearing, without reading or modifying the player's save. Use these actual renders for judging progress, rather than generating another concept image as evidence of game quality.
