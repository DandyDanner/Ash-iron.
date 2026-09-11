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
- [x] Fifteen Blender modeling/render/review cycles: full eight-model studies plus reconstructed faces, hair, profiles and garment drape on all four travelers (offline art only)
- [ ] Current art priority: close the illustration-fidelity gap in faces/hair/garments and animal anatomy, then retopology, textures, and rig/animation integration
- [ ] Later: foliage refinement from play feedback; leave the world unchanged during the character/boar work
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
- [ ] Iron ore
- [ ] Weight/encumbrance stages
- [x] Basic backpack (slot capacity; weight and upgrades remain later work)
- [ ] Furnace
- [ ] Ore smelting into ingots
- [ ] Craft one meaningful upgrade
- [x] Save/load (automatic snapshots, Continue / Start over, explicit Save & Quit with failure handling, migration of older saves)

## Phase 4 — Danger

Current agreed order: stone spear and first Bristleback Boar are playable; next comes ore → smelter → ingots → an iron weapon upgrade. Keep the same clearing while proving this loop.

- [x] Craftable stone spear, forward thrust, hotbar/save support, and practice-target melee hits

- [x] First animal/enemy: territorial Bristleback Boar, warning, straight charge, recovery, and one hide reward
- [x] Player/enemy health, safe camp recovery, and defeat returning the player with inventory intact
- [ ] Stamina
- [x] Craftable bow and arrows, draw/release, ballistics, recovery, practice target, and saved flight state
- [x] Spear and bow damage against the first animal/enemy
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
