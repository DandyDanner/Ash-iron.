# Status and handoff log

Newest first. Every session adds an entry at the top and refreshes **Now**. Keep entries short and concrete: what changed, what is half-done, what to do next.

## Now

- Build: Godot 4.7.2 on Apple Silicon. Eleven headless tests, all passing (see `README.md`, Verification). Native Godot visual review now works; reviewed clearing, front/back scout, backpack, and creator. The isolated clearing preview reported 60 FPS on the M2 at 1278 × 799; this is one scene sample, not a performance guarantee.
- Playable loop: create a traveler, gather sticks/stones, build the bench, craft tools, chop pines and mine boulders, store in chests, craft using linked chest materials, and practice with a craftable bow and recoverable arrows. Eight backpack slots and ten saved hotbar shortcuts. Automatic progress saves, Continue / Start over, and Save & Quit.
- Crafting UI: eight recipe icons with hover cards for use, have/need totals, missing ingredients, and availability. Click or keyboard-focus to inspect; use the separate craft button. Disabled recipes remain browsable. Arrow/stick icons show output amounts.
- Presentation: approved Willow Scout implemented as an articulated procedural model shared by the creator and world. Third person starts by default; V switches views and saves the preference. Walking, jumping, tool gestures, bow drawing, and cape movement. Forest paths, grass, flowers, hills, fuller pines, lichen boulders, planked bench/chest, warm sky/light, and shorter HUD. F11 toggles standalone full screen.
- Suggested next for visuals: refine the face/hair/cape and animation hand contact against `docs/art/willow-scout-turnaround.png`, replace simple distant silhouettes, vary foliage density, then add footsteps/ambient audio. This is a coordinated first procedural pass, not the finished concept-art model.
- Suggested next for systems (Phase 3): choose one meaningful expedition upgrade (ore → furnace → improved tool) or one animal for the existing bow, before expanding the map.
- Known gaps: chests can be placed on top of the bench or a boulder if the surface is flat; no confirmation before dropping a stack. Torch fuel, ore, resource regrowth, enemy damage, and background abilities remain deferred. Animation is a node rig without foot IK, skeletal skinning, or cloth simulation. The editor's embedded game controls its own window size; F11 is primarily for standalone play.

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
