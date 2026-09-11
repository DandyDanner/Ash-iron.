# Status and handoff log

Newest first. Every session adds an entry at the top and refreshes **Now**. Keep entries short and concrete: what changed, what is half-done, what to do next.

## Now

- Build: Godot 4.7.2 on Apple Silicon. Nine headless tests, all passing (see `README.md`, Verification).
- Playable loop: create a traveler, gather sticks and stones, build the bench, craft a stone axe, chop pines, craft and place storage chests, store and take items, craft from chests near the bench. Three extra bench recipes: stone pickaxe (mines boulders), pine torch (held light), and wood into sticks. Ten saved hotbar shortcuts toggle held tools. A craftable woodland bow fires recoverable arrows at an archery target; shots use gravity and save in mid-flight. Progress saves automatically; the opening screen offers Continue and Start over; the backpack has Save & Quit.
- Suggested next for the visuals lane (Phase 1 in `docs/ROADMAP.md`): replace placeholder cylinders and boxes with stylized assets, add terrain variation, establish forest lighting, fog, and sky, add footsteps and ambient audio.
- Suggested next for the systems lane (Phase 3): iron ore, weight and encumbrance stages, furnace and smelting, one meaningful upgrade.
- Known gaps: chests can be placed on top of the bench or a boulder if the surface is flat; the HUD text block is getting long; no confirmation before dropping a stack. New UI passed a viewport-bounds check, but an on-screen visual playtest is still needed (graphical Godot launch failed in the restricted execution environment). Torch fuel, ore, resource regrowth, and enemy damage remain deferred. Bow/target models are procedural prototypes; on-screen visual QA remains pending.

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
