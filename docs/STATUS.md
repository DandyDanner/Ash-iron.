# Status and handoff log

Newest first. Every session adds an entry at the top and refreshes **Now**. Keep entries short and concrete: what changed, what is half-done, what to do next.

## Now

- Build: Godot 4.7.2 on Apple Silicon. Fourteen headless tests, all passing (see `README.md`, Verification). Native Godot visual review now works; reviewed clearing, front/back scout, backpack, and creator. The isolated clearing preview reported 60 FPS on the M2 at 1278 × 799; this is one scene sample, not a performance guarantee.
- Playable loop: create a traveler, gather sticks/stones, hand-craft and place a portable bench, craft tools, chop pines and mine boulders, store in chests, craft using linked chest materials, practice with a craftable bow/recoverable arrows or a stone spear, and fight the first Bristleback Boar. Eight backpack slots and ten saved hotbar shortcuts. Automatic progress saves, Continue / Start over, and Save & Quit.
- Workbenches: craft anywhere for six sticks/four stones, carry in one slot, place on clear level ground, then use E nearby. Pick up this workbench packs it for relocation. Multiple benches persist; E selects the viewed bench, I uses the nearest reachable one. Recipes use that bench’s nearby chests; remote stock is unavailable.
- Crafting UI: nine recipe icons with hover cards for use, have/need totals, missing ingredients, and availability. Click or keyboard-focus to inspect; use the separate craft button. Disabled recipes remain browsable. Arrow/stick icons show output amounts.
- Pickaxe art: faceted stone head with a long hooked point, short rear chisel, thick lashed socket, and wrapped hardwood handle. Shared held/dropped model and matching icon.
- Tool grip: axe/pickaxe edges face forward through a back-to-forward vertical chop in both camera views, with windup/contact/follow-through and no lateral sweep. Palm grips retain forearm clearance. The redesigned bow has tapered recurve limbs, an upright palm grip, string-following draw hand, and an arrow rest above the grip.
- Presentation: approved Willow Scout implemented as an articulated procedural model shared by the creator and world. Third person starts by default; V switches views and saves the preference. Walking, jumping, tool gestures, bow drawing, and cape movement. Forest paths, grass, flowers, hills, fuller pines, lichen boulders, planked bench/chest, warm sky/light, and shorter HUD. F11 toggles standalone full screen.
- Blender: four versioned modeling/render/review cycles for all four approved travelers and all four approved animals, under `art/blender/cycles/`. Latest source: `cycle_04/characters.blend`; front/rear traveler, front/side wildlife, and scout closeup renders. References packed. Original studio baseline preserved. These are unrigged studies, excluded from Godot, with remaining illustration-fidelity work; no replacement game assets yet.
- Current art priority: Dallon expanded the art scope to Willow Scout, Hearthland Ranger, Ridge Wayfarer, Ember Forager, Bristleback Boar, Woodland Hog, Ridgeback Boar, and Meadow Buck. Improve face/hair/anatomy and garment shaping against the illustrations before topology, baked textures, skinning, and integration. World/gameplay stay unchanged. Bear remains later.
- Later visuals, after character/boar approval: refine the face/hair/cape and animation hand contact against `docs/art/willow-scout-turnaround.png`, replace simple distant silhouettes, vary foliage density, then add footsteps/ambient audio. This is a coordinated first procedural pass, not the finished concept-art model.
- First enemy: Bristleback Boar in the back-left grove; readable warning, committed charge, recovery, and obstacle/territory limits. 60 health, spear 20 / arrow 25 damage, one collectible hide. Traveler health is 100, charge damage 25; defeat returns to starting camp with inventory intact. Camp gradually heals. Panels/focus loss pause combat. Health, defeated state, and loot persist in save format 6; formats 1–5 migrate safely. No respawn or hide recipes yet.
- After the character/boar art milestone: ore → smelter → ingots → an iron weapon upgrade. Approved later wildlife: Woodland Hog, Ridgeback Boar, Meadow Buck; bear later. Keep the current clearing while proving the loop.
- Known gaps: no placement ghost or manual rotation tool yet (furniture follows the player’s horizontal facing); no confirmation before dropping a stack. Torch fuel, ore, resource regrowth, stamina, and background abilities remain deferred. Animation is a node rig without foot IK, skeletal skinning, or cloth simulation. The editor's embedded game controls its own window size; F11 is primarily for standalone play.

## 2026-09-11 — ChatGPT / Codex: eight-model Blender review cycles

- Dallon asked for repeated create/review/improve cycles, then explicitly expanded to all four travelers and all four animals. Started clean/even at `267a26a` with personal Git identity. Built original offline mesh/material studies in separate collections; packed the three approved reference images and preserved earlier versions.
- Four real Blender passes, each saved and rendered. Reviews drove reduced facial projection, better mesh boundaries, grounded feet and connected deer legs, thinner laid-down boar fur, changed hair orientation, cloak/sleeve clearance, outfit differences, backpack detail, and deer neck/throat refinements. See `art/blender/cycles/REVIEW.md` for candid visual findings and remaining shortcomings. These models still look simplified compared with the illustration; no finished sculpt fidelity is claimed.
- No runtime script, scene, world, combat, save, or customization changes. Source remains behind `.gdignore`. Final studies need further art refinement, retopology, UV/baked materials, skeletal rigging/weights, animation/equipment checks, and a tested game import. The prior open Blender session was copied outside the repo to `outputs/blender-session-before-eight-models.blend` before changing its view.
- Verification: all fourteen gameplay suites returned their PASS markers and exit 0; sandbox logging could not write the default Godot log, but test output and isolated save checks succeeded. Actual native Blender source/renders were checked separately. Next is review of these studies with Dallon before treating any model as approved for integration.

## 2026-09-10 — ChatGPT / Codex: Blender modeling workspace

- Dallon installed Blender and asked to continue from its welcome screen. Completed Quick Setup with the displayed defaults, verified Blender 5.2.1 LTS scripting and GLB support. Started clean/even at `512e617` and verified personal Git identity.
- Added a reproducible Blender studio with separate existing scout/boar prototype collections, packed approved reference sheets, modeling notes, and a review-only camera/light setup. This is a baseline modeling workspace, not new high-fidelity art. `art/blender/.gdignore` prevents source files from being auto-imported into the game; world and runtime files are untouched.
- Verified a complete Godot → Blender → Godot round trip: 321 mesh nodes and dimensions (2.806, 2.095, 2.139) meters for the staged pair. Removed hidden hand geometry only from the baseline export to avoid Blender’s unsupported required `KHR_node_visibility` extension; live model code is unchanged.
- Opened the studio in native Blender; the file browser stalled, so loaded the saved file through Blender’s own console. Fourteen gameplay suites pass. Next: author complete models against the packed references, save to new versioned Blender filenames, then review geometry/textures and establish animation/skin weights before integrating approved GLBs. The existing node hierarchy is reference information, not a finished skeletal rig.

## 2026-09-10 — ChatGPT / Codex: character and boar art refinement

- Dallon requested polish on the scout and boar only, aiming toward the earlier concept illustrations. Started clean/even at `7bfa7b5` and verified personal identity. Clarified that those illustrations were not rendered game assets and that this pass does not achieve their finished sculpt/texture fidelity.
- Added isolated `character_mesh.gd` surface helpers for higher resolution rounded forms and curved tapered locks. Existing shared world/prop helpers remain unchanged. Scout gains swept hair with tied tuft and retained style choices, shaped facial features, eyelids/lips, subtle garment folds, a broader embroidered cape, and a hanging folded hood. Boar gains rounded body/snout, curved tusks, muzzle ridges, inset ears, brows, and layered fur following the body surface.
- Kept the existing rig dimensions, hand sockets, animation behavior, customization, collision, combat, saves, world geometry, foliage, lighting, and props. Remaining limitations: simplified anatomy and materials, some rigid garment intersections during motion, no sculpted textures, skeletal skinning, or simulated fur/cloth. The next substantial quality step is authored character/creature assets rather than declaring the concept target met.
- Verification: all fourteen suites pass; reran boar coverage after the final fur placement adjustment. Native Godot rendered scout front/back/face and boar portraits, plus both in the unmodified clearing. Review caught and corrected protruding cheek pieces, submerged lips, cape shoulder clipping, and fur orientation. `tests/art_portrait.gd` reproduces actual renders using isolated profile/save paths; studio lighting is confined to that utility and does not change the game.

## 2026-09-10 — ChatGPT / Codex: first Bristleback Boar encounter

- Dallon approved #1 in the four-animal progression and asked to implement it. Started clean at `ffcd3da`, checked origin and personal identity. Added the approved wildlife sheet and `docs/art/BRISTLEBACK.md`.
- Added original procedural boar art with shaped body/snout, curved tusks, amber eyes, cloven hooves, russet fur, and dark mane; animated gait, warning paw, lowered charge head, and hit recoil. This remains simplified in-game art rather than a finished sculpt matching the illustration.
- Boar notices within eight meters, warns for one second, charges in a locked direction, and recovers for 1.6 seconds. Solid obstacles stop the charge; short probes steer approaches/returns around trunks. Camp is safe; leaving the territory resets it at home. A native preview and combat test caught a tree overlap at the initial home; moved home to (-15, 0.22, -13) and corrected collider height.
- Connected actual spear/bow contact to 60 enemy health, one hide drop, and persistent defeat. Added 100 player health, 25 charge damage, brief damage grace, safe defeat with retained inventory, and gradual healing near the original spawn. Panels/focus loss suspend combat. Save format 6 adds health/enemy state; older saves preserve belongings and receive healthy defaults. No enemy respawn, meat/leather recipes, ore, or smelting in this step.
- Verification: all fourteen headless suites pass, including new encounter tests for warning/dodge/charge, recovery, pause/walls/territory, actual weapon hits, one reward, defeat/healing, persistence, malformed data, and format 5 migration. Native Godot inspected the first model in the clearing. Isolated visual preview adds B for the encounter and N for the boar portrait; real saves remain separate.

## 2026-09-10 — ChatGPT / Codex: craftable stone spear

- Dallon requested a sword or spear to start melee progression, then agreed to stone spear → first enemy → ore and smelting. Started clean at `a912cdc`, verified origin and personal identity.
- Added a workbench recipe (2 wood + 2 stones), connected-storage support, ninth craftable icon/hover recipe, one-slot equippable spear, and existing hotbar/storage/drop/save integration. Shared original art uses a leaf-shaped stone point, lashings, wrapped shaft, and butt cap in both views and pickups. New travelers still start empty-handed.
- Left click performs a short forward thrust through the existing attack timer: contact at 0.22 seconds, 0.6-second cooldown, one hit per attack. A 2.8-meter ray starts at the traveler, excludes loose pickups, and stops at the first solid obstacle. The practice target accepts `receive_melee_hit(damage, point)` and gives spear feedback. The spear supplies 20 damage for the next enemy implementation; the practice target only scores hits. No enemies, health, ore, smelter, throwing, or blocking yet.
- First-person motion travels forward without roll. Third-person arm follows the palm beside the body; the shaft clears torso/forearm. Equipment switches, menus, view changes, focus loss, and fall recovery cancel pending attacks. Spears do not chop or mine. Save format remains 5 because existing item/hotbar/pickup fields already support the new item; no migration or free items are needed.
- Verification: all thirteen suites pass. The spear suite covers connected recipe costs/full-pack failure, both views, hit timing/cooldown, range/walls, cancellation, non-harvesting, grip/body clearance, chest transfers, hotbar/save round trips, and dropped recovery. Native Godot inspected first-person carry and third-person carry/thrust. Temporary preview inventory now includes the spear; T cycles its poses.

## 2026-09-10 — ChatGPT / Codex: shaped stone pickaxe

- Dallon liked the corrected swing but found the pickaxe head too oval. Started clean at `80acd06`, verified origin and identity.
- Replaced the oval with an original faceted stone head: a long downward-curved point, shorter rear chisel, and thick center socket secured with rawhide bands. Added a tapered hardwood haft and wrapped grip. Shared `pickaxe_art.gd` serves held and dropped tools; inventory/crafting/hotbar icons match the new silhouette.
- Native Godot reviewed the side silhouette in third person and the details in first person. All twelve suites pass, including mining, both swing paths, and forearm clearance through the swing. Animation, recipes, damage, reach, and saves are unchanged.

## 2026-09-10 — ChatGPT / Codex: forward swings in both camera views

- Dallon clarified that both tools should lift back and hit forward instead of sweeping right-to-left. Started clean at `54b0889`, checked origin and identity. The prior fix had left the old first-person roll and lateral translation intact.
- Replaced that first-person sweep with pitch-only backswing, forward/downward contact, follow-through, and recovery. Turned both first-person cutting edges forward. Removed third-person chopping arm roll so both views keep the head in a fixed vertical plane. Hit timing, cooldown, reach, harvest rewards, bow, and saves are unchanged.
- Extended the isolated pose preview to cover pickaxes and first-person gear. Native Godot reviewed first-person backswing/forward impact poses. All twelve suites pass; regression checks sample complete axe/pickaxe swings in both views for lateral drift, forward/downward travel, cutting direction, and forearm clearance.

## 2026-09-10 — ChatGPT / Codex: axe cutting direction and bow redesign

- Dallon found the axe blade and bow sideways. Started clean at `f151c70`, checked origin and personal identity. Rotated the axe/pickaxe cutting plane forward and replaced the backward lifting gesture with windup, forward contact at 0.22 seconds, follow-through, and recovery. Kept the palm clearance fix.
- Rebuilt shared bow art with smooth tapered recurve limbs, pale tips, bindings, and a centered wrapped grip. Limbs flex during drawing. Third-person bow orientation stays upright independently of the arm; two-segment arm posing meets the grip and drawn string without stretching. Left fingers wrap the grip. Arrow nock meets the string and the shaft sits above/beside the grip. Shared first-person, stowed, and pickup bows use the redesign.
- Added isolated portrait pose/orbit controls (O, then J/K/L) for inspection. Native Godot reviewed axe contact and the bow from multiple angles, plus first-person bow presentation. Saved the real play session before previewing.
- Verification: all twelve suites pass, including added checks for blade direction and forward head travel at contact, forearm clearance through windup/swing, upright bow, forward arrow, grip/draw hand contact, and string/nock alignment. Recipes, hit timing/reach, shot physics, and save format 5 remain unchanged.

## 2026-09-10 — ChatGPT / Codex: third-person tool grip

- Dallon reported the held axe intersecting the forearm. Started clean at `6d0a73b` and checked origin/identity.
- The copied first-person tool geometry had its long axis pointing back toward the elbow. Added a palm grip that turns the axe, pickaxe, and torch across the hand; the axe blade faces outward. The fingers close around the shaft when equipped and relax when holstered. The carrying arm is held slightly farther from the body.
- First-person tool placement, attack timing/reach, inventory, and saves are unchanged. Bow attachment remains separate.
- Verification: all twelve suites pass. The third-person suite now checks actual rendered tool vertices against the forearm volume through idle and swing poses for all three tools, plus gripping/relaxed finger visibility. Native Godot front-view inspection confirms the axe sits in the hand with the head clear of the arm. Saved the user's active play session before switching to the isolated preview.

## 2026-09-10 — ChatGPT / Codex: portable workbenches

- Dallon requested placing the crafting table anywhere like a chest. Started clean at `b69ef7d`, checked origin and identity, and replaced the fixed worksite with a hand-crafted inventory item (6 sticks + 4 stones, one slot).
- Added Place workbench here and Pick up this workbench. Multiple tables are supported; E selects the viewed bench and its connected chests, while I uses the nearest reachable bench. Tool crafting requires a placed bench within reach and line of sight. E has broad targeting for a nearby table so a level view can use it. Picking up the bench leaves chest contents intact. Hand crafting away from workshops uses only backpack materials.
- Shared placement checks now cover benches and chests: whole footprint, ground-only surfaces, slope/height variation, line of sight, and overlap. Explicit furniture footprint checks reject two placements in the same physics frame. This also fixes placing chests on benches/boulders. No placement preview/rotation controls added; facing determines orientation.
- Save format 5 records all workbench positions/yaws. Formats 1–4 migrate a built camp bench to one portable table at (-3.5, 0.2, 0.3); unbuilt worksite markers are removed. Portable bench inventory and dropped pickups use the existing persistence rules. Other progress stays intact.
- Updated craftable hover text, backpack placement action, pickup control, onboarding, and test fixtures. Tests of established workshops explicitly create a fixture bench now; the first-resource-loop test exercises crafting and placing the actual item.
- Verification: all twelve headless suites pass, including new coverage for placement failures without consumption, same-frame overlap, multiple benches, E selection and storage context, full-pack pickup failure, packing/relocation, saves/migration, and dropped item recovery. Native Godot preview checked the craft/place/pick-up controls.

## 2026-09-10 — ChatGPT / Codex: craftable icons and hover recipes

- Dallon requested icons for craftables with recipe and item-use information on hover. Started from clean `d01cddd`, verified origin and personal commit identity.
- Replaced the long recipe list with an eight-icon grid. Reused the game's existing item icons and added an original workbench icon. Batch arrows/sticks show ×5/×4; READY, UNAVAILABLE, OWNED, and BUILT labels accompany visual dimming.
- Hover cards show purpose, have/need materials, missing quantities, and current station/capacity requirements. Click or keyboard-focus a tile to retain details beneath the grid; a separate build/craft button spends materials. Unavailable icons stay enabled for inspection.
- Uses the existing recipes and atomic crafting functions, with live backpack/linked-storage counts; no save or progression changes. Added an isolated integration test for browsing without spending, focus, exact build/craft outcomes, linked storage, quantities, and viewport bounds.
- Verification: all eleven headless suites pass; reviewed grid and hover presentation in the isolated native Godot preview. The detailed character model requested in the preceding discussion remains a future focused art milestone.

## 2026-09-10 — ChatGPT / Codex: Willow Scout and coordinated graphics pass

- Dallon approved Willow Scout (#1) and requested graphics, third person, and movement/tool presentation together. Started from clean `811f209`, checked origin before publishing, and retained all progression rules and stable test/save node names.
- Added the approved original concept sheets and art direction under `docs/art/`. Rebuilt the shared traveler using shaped meshes, articulated arms/legs, detailed boots, cape trim, sash, pouches, hair and face choices, and cosmetic keepsakes. Saved appearance remains editable.
- Added a collision-aware spring-arm camera, V view toggle, close-wall body hiding, closer bow-draw camera, and separate render layers for body versus first-person hands. Owned tools show in the hands; stowed bow/quiver/arrows follow actual backpack contents. New characters still start empty-handed.
- Tool contact and arrow launch stay at the player's head, aimed toward the third-person crosshair, preserving tool/pickup reach and close obstruction. Walking/jumping/chopping/drawing animate the body and cape. F11 offers a standalone full-screen shortcut.
- Added flat-center/rolling-edge terrain, paths, wind grass, flowers, distant silhouettes, and 32 named harvestable grove pines. Existing four pines, resource positions, mining, crafting, and storage remain compatible. Updated bench/chest planks and hardware, lichen on boulders, shared matte shading, sky/light/fog, creator stage, panel corners, and concise HUD controls.
- Save format 4 stores camera mode. Formats 1–3 retain progress and default to third person when the field is absent; new grove trees subsequently persist like existing trees.
- Verification: all ten headless suites pass. New suite covers third/first camera selection, wall retraction/recovery, empty gear, pickup distance/occlusion, actual axe/bow contact, obstruction, draw cancellation, animation, terrain normals/collision, camera persistence, and format 3 migration. Native Godot visual inspection caught and corrected inward-facing mesh triangles. No shader errors appeared in the graphical run.
- `scenes/visual_preview.tscn` is an isolated manual QA scene with temporary equipment/profile/save, portrait toggle (O), and viewport capture (P). Run Project returns to the real game; never make this preview the main scene.
- No half-written feature remains. Next handoff should gather feedback on camera feel and the simplified character before detailed asset work.

## 2026-09-10 — ChatGPT / Codex: bow and archery practice

- Dallon requested a bow and asked when to work on graphics. Started from clean `f18f799`, checked GitHub first, and extended the existing recipes, hotbar, and save code.
- Added woodland bow (3 wood + 2 sticks) and bundles of five arrows (2 sticks + 1 stone) at the bench, including connected-storage materials. Bow assigns/equips like the existing tools. Inventory arrow stacks cap at ten.
- Hold left click to draw for up to 0.85 s; release fires once at 12–32 m/s depending on charge. Very short taps do not fire. Right click, menus, switching gear, and focus loss cancel without spending ammo. HUD shows draw percent and arrow count.
- New target at (10, 0.2, -9), facing the clearing, reports bullseye/inner/outer hits. Practice count resets per visit. No enemy health/damage, hunting, or tool harvesting from bows yet.
- Arrows use swept collision rays and gravity, exclude the shooter, and become one E-recoverable pickup on impact. Shots leaving the clearing or exceeding eight seconds are lost. Added original procedural held/dropped bow and arrow models plus icons.
- Save format is now 3; formats 1 and 2 still load. Flight snapshots store position/velocity/age; landed arrows reuse saved pickups. Saving mid-shot preserves exactly one arrow.
- Tests: nine headless suites pass, including new bow recipe/draw/cancel/ballistics/target/obstruction/recovery/save/migration coverage. Visual playtest remains pending in the normal Godot game window.
- Recommended next: a focused graphics pass on this same clearing (ground, trees, sky/light, tool silhouettes), then one animal/enemy. Avoid expanding the map until the small area feels good.

## 2026-09-10 — ChatGPT / Codex

- Dallon authorized this gameplay pass after Claude's completed handoff. Started from `4528414`, clean and even with GitHub; checked origin again before publishing. Preserved Claude's chest, connected-storage, and save architecture.
- Added 1–9/0 hotbar shortcuts. Assign by selecting a backpack tool and pressing/clicking a number; select an empty slot to clear. Press the assigned key to equip or holster. Shortcuts reference item types, add no inventory capacity, and stay dimmed if the item is stored or dropped. First equip assigns a free shortcut automatically.
- Added bench recipes: pickaxe (3 sticks + 4 stones), pine torch (2 sticks + 1 wood), split timber (1 wood → 4 sticks). New recipes share atomic connected-storage planning. Pickaxes take four hits to deplete a boulder and drop two stones per hit. Axes cannot mine, and pickaxes cannot chop. Torches provide held light with no fuel upkeep yet.
- Backpack now has a scrollable recipe column and Save & Quit; Esc opens the backpack. Window close and C are guarded by successful saving. Save errors leave the world open and show an explanation. Focus-loss resume still does not attack.
- Save format is now 2: adds hotbar, held item, and boulder damage. Format 1 saves load without resetting progress; old axes gain shortcut 1. Future changes should retain this migration.
- Final tree hits now create the wood bundle immediately, so saving/quitting during the visual fall cannot lose the reward. Loading never duplicates it.
- Tests: all eight headless suites pass, including new hotbar/recipe/mining/migration/Save & Quit coverage and panel bounds. All test saves now live in the OS temporary folder via `tests/test_paths.gd`; the real traveler and clearing are untouched.
- Next handoff: playtest visual size/readability of the hotbar and recipe scroll, then choose either forest art/lighting or the first ore-processing loop. No half-written gameplay work remains.

## 2026-09-10 — Claude Code

- Added storage chests (craft 5 wood + 2 sticks at the bench, place on clear ground, open with E, store and take, pack up when empty).
- Added automatic save and load of the whole clearing (`user://save.json`): player pose, backpack, equipped axe, workbench, tree damage, loose and dropped resources, chests with contents. Saves a moment after changes, on closing panels, every 15 s, on C, and on window close. Opening screen: Continue your journey, and a two-step Start over that keeps the traveler.
- Bench recipes now draw from the backpack first, then from chests within about eight meters of the bench. Nothing is consumed unless the whole recipe fits.
- Set up the handoff: `AGENTS.md`, `CLAUDE.md`, this file. Git identity is pinned machine-wide for every DandyDanner repository with a pre-push guard.
- Tests: chest storage, save/load, connected storage added; the older four isolated from the real save file.

## 2026-09-10 — ChatGPT / Codex (earlier)

- Project scaffold, HUD and environment, traveler character creation with saved appearance, jumping, starter axe with tree chopping and wood pickup, limited backpack with gathering-to-workbench crafting, forgiving E pickups. (Summarized from git history.)
