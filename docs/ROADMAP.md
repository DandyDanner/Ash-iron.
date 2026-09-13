# Prototype Roadmap

## Rule

Every new feature must answer three questions:

1. Does it make expeditions more interesting?
2. Does it make progression more satisfying?
3. Is it worth the development cost?

If it fails two of the three, cut or defer it.

## Phase 0 — Foundation

- [x] Godot project scaffold
- [x] Simple 3D test scene
- [x] First-person walking/mouselook
- [x] Jumping, landing, and recovery after falling off the test clearing
- [ ] Establish project naming conventions
- [x] Confirm clean launch on M2 Mac (Godot 4.7.2)
- [x] First character-creation prototype: cosmetic backgrounds, editable appearance, keepsake, local profile save

## Phase 1 — Ten good seconds

Goal: make simply moving through the prototype world feel competent.

- [ ] Tune player speed and camera feel
- [x] First coordinated stylized asset pass: Willow Scout, trees, rocks, bench, chest, and shared materials
- [x] Supplied textured pines with distance meshes, hollow hinged chest, and shared stone/copper/iron cluster art with matching icon colors; existing interactions and saves preserved
- [x] Third-person camera with wall collision, first-person toggle, walking/jumping/tool/bow poses
- [x] Forward+ rendering pass within the retina 60 fps budget: soft shadows, SSAO, ACES, linear meadow colors, and per-traveler 1024 face maps with painted eyes, lids, brows and lips
- [x] Modern HUD bars and compact hotbar; backpack shows all twelve slots with hover cards; crafting never scrolls to reach Craft
- [x] Bellmaw shoulder-anchored swipe, four-beat walk, calm home patrol and native eyelid blink
- [x] Rodin equipment in both views and pickups; native workbench/furnace with earned copper kit and state-driven fire; chest retained
- [x] First-person swings pivot at the elbow; bare-handed punch (3 damage); pines take ten stone-axe hits or five copper swings, with save migration
- [x] Focused procedural scout/boar refinement: smooth forms, swept hair, face details, patterned cape/hood, tusks, and layered fur
- [x] Blender modeling studio, packed references, and verified GLB round trip to Godot
- [x] Twenty-six Blender modeling/render/review cycles: reconstructed traveler faces/ears/hair/garments and wildlife anatomy, fitted eyes, coats and hooves (offline art only)
- [x] Native Rodin Bellmaw and Bristleback replacements; animated Hollow Wolf and Meadow Buck preview assets, with editable rigs and original PBR maps
- [x] Approved native-textured Willow replacement, 14-bone skin, original PBR maps and Willow-specific weapon fit; preserved traveler selection and earned archery gear
- [x] Four supplied Rodin travelers with painted 2K textures, surface-based skins, separate open fingers and preserved selection/saves
- [x] Willow’s visible archery gear follows inventory; removed sculpted bow/arrow tips and fitted earned carry props clear of her bag
- [x] Four selectable Blender traveler exports with a first skinning pass, existing movement/tool animation, persisted choice, and original customization retained
- [x] First-person articulated hand meshes and weapon grips; traveler surface materials, boar fur/hooves and Bellmaw silhouette refinement (actual Godot review)
- [x] Focused Willow face/hair reconstruction with matched native comparisons, preserved other models and a refreshed playable export
- [x] Articulated Bellmaw ground slam, paw dust, exhausted recovery and warned left/right swipe with cooldown/cover/dodge tests
- [x] Isolate the largest supplied Bellmaw, build weighted skeleton/movement, integrate and verify actual Godot combat/rendering
- [x] Offline repair candidate for the uploaded Willow sheet: isolate front figure, replace corrupt head and fit neck/collar; preserve current playable traveler
- [ ] Further optimize the approved Willow rig, sleeve/wrist transitions and cape deformation; refine Bellmaw foot contact and facial detail
- [x] Prepare supplied leather backpack as an optimized reusable Godot asset; review textures and silhouette
- [ ] Fit backpack straps/cape attachment and resolve existing equipment overlap before displaying the Explorer Pack upgrade
- [ ] Current art priority: focus on Willow Scout first; close the illustration-fidelity gap in faces/hair/garments and animal anatomy; optimize topology/materials and improve joint deformation. Wildlife integration remains later.
- [ ] Later: broader foliage refinement from play feedback; the September 11 Echo Hollow excursion is the only new world slice in this pass
- [x] Add terrain variation
- [ ] Add basic footsteps/ambient audio
- [x] Establish initial forest lighting/fog/sky direction

## Phase 2 — One resource loop

Goal: walk out, collect one thing, bring it home.

- [x] Interactable tree
- [x] Axe swing
- [x] Tree health / hit response
- [x] Wood pickup (five wood per tree, into available backpack space)
- [x] Minimal inventory (eight slots; resource stacks of ten; equip/drop/recover)
- [x] Gather loose sticks and stones without tools
- [x] Hand-craft a portable workbench, place on clear ground, pick up and relocate
- [x] Multiple saved workbenches with nearby crafting and storage connections
- [x] Craft the first stone axe from gathered materials
- [x] Ten saved hotbar shortcuts with equip / put-away toggles
- [x] Craftable icon grid with hover recipes, material counts, item uses, and explicit craft action
- [x] Stone pickaxe, mineable boulders, pine torch, and wood-to-sticks recipes
- [x] Placeable storage chest at camp (twelve slots; store, take, pick up and move)
- [x] Hover + T transfers chest/backpack stacks both ways; Tab toggles inventory, I stays an alias, arrow keys navigate
- [x] Crafting pulls from connected home storage (chests near the bench, backpack first)
- [x] Mining fragments fall to terrain, ignoring player/furniture collision tops

## Phase 3 — First expedition loop

- [x] Loose stone gathering
- [x] Iron ore (three surface veins, four strikes each, plus a sporadic chunk from boulders)
- [ ] Weight/encumbrance stages
- [x] Basic backpack (eight slots) and a permanent twelve-slot Explorer Pack upgrade; weight remains later
- [x] Furnace (10 stones + 2 wood; craft at the bench, place anywhere level, load with E)
- [x] Furnace auto-feed from chests within 8 m, atomic one-batch reservation, saved toggle and manual backpack/linked load
- [x] Ore smelting into ingots (two ore + one wood per ingot, twelve seconds each, runs unattended)
- [x] Craft one meaningful upgrade: Bellmaw hide + wood/sticks → Explorer Pack
- [x] Save/load (automatic snapshots, Continue / Start over, explicit Save & Quit with failure handling, migration of older saves)

## Approved crafting direction — September 11

**Stone → Copper → Bronze → Iron → Steel** is the approved target. See [Craftsman progression](CRAFTSMAN_PROGRESSION.md). Stone/copper and earned workshop unlocks are now playable. The original iron-furnace prototype remains compatible; bronze, iron equipment and steel are future work.

- [x] Agree on the five material stages
- [x] Inventory-crafted stone axe, pickaxe and spear; clear station requirements for other recipes
- [x] Copper source, primitive smelting, first copper item and fittings for an improved crafting station
- [x] Preserve existing iron, furnace contents/queues and saved progress when introducing the new order
- [ ] Playtest the fresh stone/copper loop with eight inventory slots before adding later stages
- [ ] Tin discovery and bronze alloying/casting
- [ ] Iron forging and workshop capability
- [ ] Steel refinement, heat treatment and specialized tools
- [ ] Later, after wearable armor: ore/metal/mineral decoration with selectable trim, inlays and emblems; appearance independent of protection (see craftsman plan)

## Phase 4 — Danger

Current order: spear and Bristleback Boar → ore/furnace → one strange creature at Echo Hollow → Explorer Pack. The stone/copper foundation above is playable; playtest it before adding tin/bronze and later iron equipment. Dallon approved a small outer excursion on September 11; larger biomes and a full enemy roster remain deferred.

- [x] Craftable stone spear, forward thrust, hotbar/save support, and practice-target melee hits

- [x] First animal/enemy: territorial Bristleback Boar, warning, straight charge, recovery, and one hide reward
- [x] Player/enemy health, safe camp recovery, and defeat returning the player with inventory intact
- [x] Bellmaw: warned radial boom, distance/cover counterplay, recovery, one saved hide reward per defeat
- [x] Double Bellmaw body dimensions, matching collision/obstacle clearance and raised cues; warning ring now expanded to the actual blast radius
- [x] Expand Bellmaw boom to 7 m, matching warning ring and approach trigger; planted anticipation, impact compression and weighted paw swipe
- [x] More dangerous Bellmaw: 300 health, guarded hide, 34-damage boom, faster pursuit and shorter recovery
- [x] New supplied Bellmaw sculpt: isolated largest creature, optimized/colorized/rigged, twice the previous runtime size with matching collision and paw reach; old save health percentages preserved
- [x] Both enemies respawn after 120 active seconds, away from the player and only into clear space; timer persists
- [x] Echo Hollow trail, marked warning, cover rocks, harvestable pines and Old Lookout iron vein
- [x] Health/stamina HUD in both camera views, low-health/exhaustion cues, sprint drain/recovery and saved reserve
- [ ] Extend stamina costs to combat/jumping after playtesting sprint pressure
- [x] Craftable bow and arrows, draw/release, ballistics, recovery, practice target, and saved flight state
- [x] Spear and bow damage against the first animal/enemy
- [x] Axe as a backup melee weapon: 10 damage versus spear 20, existing chopping retained; durability/breakage deferred
- [x] Basic hit recoil and health feedback
- [ ] Death + recoverable carried loot
- [ ] Basic day/night pressure
- [ ] Later wildlife progression: Woodland Hog → Ridgeback Boar → Meadow Buck; bear after those

## Phase 5 — Prototype 0.1

- [ ] Flintlock
- [ ] Basic firearm fouling/wetness concept
- [ ] Three creature/enemy archetypes total
- [ ] One small ruin/cave
- [ ] One boss or major threat
- [ ] One workshop/progression unlock
- [ ] 30-60 minutes of coherent gameplay

## Explicitly deferred

Do not build these until the core loop is proven:

- Rideable sled physics
- Pack animals
- NPC settlement growth
- Full skill tree
- Advanced weather simulation
- Multiple large biomes
- Large freeform building system
- Dynamic ecosystem simulation
- Cart/wagon
- Multiplayer
- Background classes and abilities (background selection is cosmetic for now)

## Next playtest and design boundaries — September 11

- Check health/stamina readability and sprint reserve when dodging Bellmaw; current stamina costs apply only to sprinting.
- Test finding Echo Hollow from camp, reading the throat warning, retreating behind cover, and bringing its hide home for four more slots.
- Retest the stronger boom and armored hide: punish recovery instead of trading repeated spear hits. Check the two-minute respawns, chest-fed twelve-second smelting and falling mining drops.
- Tune this one encounter before adding Threadwing or another enemy. Bellmaw is the first strange creature; Threadwing remains an approved future concept.
- This slice answers the three feature questions: an optional outer route adds expedition choices; a guaranteed hide buys useful carrying capacity; shared weapons, inventory and terrain keep implementation bounded.
- [Creature direction](CREATURE_DIRECTION.md) preserves Threadwing, Night Harrow, StoneWraith, Gloam Feeder and the lantern/discovery/villager ideas. XP levels, armor and additional biomes remain later. Timed enemy respawns now support repeated balance testing.
