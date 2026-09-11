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
- [x] Third-person camera with wall collision, first-person toggle, walking/jumping/tool/bow poses
- [x] Focused procedural scout/boar refinement: smooth forms, swept hair, face details, patterned cape/hood, tusks, and layered fur
- [x] Blender modeling studio, packed references, and verified GLB round trip to Godot
- [x] Twenty-six Blender modeling/render/review cycles: reconstructed traveler faces/ears/hair/garments and wildlife anatomy, fitted eyes, coats and hooves (offline art only)
- [x] Four selectable Blender traveler exports with a first skinning pass, existing movement/tool animation, persisted choice, and original customization retained
- [x] Focused Willow face/hair reconstruction with matched native comparisons, preserved other models and a refreshed playable export
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
- [x] Crafting pulls from connected home storage (chests near the bench, backpack first)

## Phase 3 — First expedition loop

- [x] Loose stone gathering
- [x] Iron ore (three surface veins, four strikes each, plus a sporadic chunk from boulders)
- [ ] Weight/encumbrance stages
- [x] Basic backpack (eight slots) and a permanent twelve-slot Explorer Pack upgrade; weight remains later
- [x] Furnace (10 stones + 2 wood; craft at the bench, place anywhere level, load with E)
- [x] Ore smelting into ingots (two ore + one wood per ingot, six seconds each, runs unattended)
- [x] Craft one meaningful upgrade: Bellmaw hide + wood/sticks → Explorer Pack
- [x] Save/load (automatic snapshots, Continue / Start over, explicit Save & Quit with failure handling, migration of older saves)

## Phase 4 — Danger

Current order: spear and Bristleback Boar → ore/furnace → one strange creature at Echo Hollow → Explorer Pack. Iron equipment remains next in the metal chain. Dallon approved a small outer excursion on September 11; larger biomes and a full enemy roster remain deferred.

- [x] Craftable stone spear, forward thrust, hotbar/save support, and practice-target melee hits

- [x] First animal/enemy: territorial Bristleback Boar, warning, straight charge, recovery, and one hide reward
- [x] Player/enemy health, safe camp recovery, and defeat returning the player with inventory intact
- [x] Bellmaw: warned radial boom, distance/cover counterplay, recovery, single saved hide reward
- [x] Echo Hollow trail, marked warning, cover rocks, harvestable pines and Old Lookout iron vein
- [ ] Stamina
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

- Test finding Echo Hollow from camp, reading the throat warning, retreating behind cover, and bringing its hide home for four more slots.
- Tune this one encounter before adding Threadwing or another enemy. Bellmaw is the first strange creature; Threadwing remains an approved future concept.
- This slice answers the three feature questions: an optional outer route adds expedition choices; a guaranteed hide buys useful carrying capacity; shared weapons, inventory and terrain keep implementation bounded.
- [Creature direction](CREATURE_DIRECTION.md) preserves Threadwing, Night Harrow, StoneWraith, Gloam Feeder and the lantern/discovery/villager ideas. XP levels, armor, enemy respawn and additional biomes are not part of this slice.
