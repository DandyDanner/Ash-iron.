# Ash & Iron

Working repository for a stylized frontier crafting-survival adventure.

## Current goal

Build a small, playable Godot prototype before expanding the design. Prototype 0.1 should prove that moving through the wilderness, gathering resources, returning home, and progressing feels good.

## Design pillars

- Exploration and combat with a third-person starting view and an optional first-person view
- Medium survival pressure without constant meter babysitting
- Safer homestead, increasing danger and richer resources toward the mountains
- Raw ore must be hauled home and smelted into usable metal
- Weight matters during expeditions; backpacks, sleds, and later pack animals help beat the logistics problem
- Crafting at home pulls from connected storage automatically
- Equipment progression improves output, durability, efficiency, and capability
- Selective maintenance: firearm fouling/wetness and blade sharpness, without excessive busywork
- Small, meaningful skill tree focused on new capabilities rather than tiny percentage bonuses
- A handful of specialist NPCs are attracted by opportunity; no settlement-management spreadsheet
- 2-3 purposeful gear families rather than dozens of loot sets
- Natural ground slowly regrows vegetation; maintained/build areas suppress regrowth
- Clean, colorful, stylized 3D visual direction inspired by Zelda-like readability
- Game 1 must have a satisfying ending while leaving room for future regions and expansion

## Starter controls

- The project opens with character creation. Choose a background, customize your traveler, pick a keepsake, then select **Begin your journey**.
- Backgrounds and keepsakes are cosmetic. Classes and abilities are deferred.
- `W A S D` — move
- `Shift` — sprint
- `Space` — jump
- Mouse — look / orbit the traveler while standing still
- `V` — switch third person / first person; the choice is saved
- `F11` — toggle full screen in a standalone game window (some Mac keyboards need Fn)
- Left click — swing your equipped axe or pickaxe; with a bow, hold to draw and release to fire (while the mouse is captured)
- Right click — cancel a bow draw without spending an arrow
- `E` — gather sticks, loose stones, or wood; use the camp worksite or bench; open a storage chest
- `I` — open or close your backpack and crafting panel
- `Esc` — open the backpack and save controls; close an open panel
- Click game window — capture mouse again
- `C` — return to character creation (your progress is saved first)
- `1`–`9`, `0` — equip a hotbar tool; press its key again to put it away
- In the backpack, select a tool and press a number or click a shortcut button to assign it. Select an empty backpack slot to clear that shortcut.
- Progress saves automatically. **Save game** saves on demand; **Save & Quit** saves successfully before closing the game. A failed save keeps the game open.

## Run it

1. Install the current stable Godot 4 release for Apple Silicon.
2. Open `project.godot` in Godot.
3. Press **F5** or the **Run Project** button in the top-right. On some Mac keyboards use **Fn + F5**.
4. Create your traveler, or choose **Continue your journey**, then enter the stylized forest clearing. On Mac, **Command + B** also runs the project.

Your name and appearance are saved locally between launches. They are separate from the clearing save. The character is an original procedural art blockout, ready for feedback before investing in a finished model. See `docs/CHARACTER_CREATION.md` for the current feature set.

## Coordinated visual pass

The approved **Willow Scout** guides the shared character model: a short sage cape, cream sleeves, teal sash, leather pouches, and folded boots. Saved skin, hair, build, clothing color, and keepsake choices still apply. Walking, sprinting, jumping, chopping, and drawing the bow move the articulated body. A spring-arm camera retracts near solid obstacles and moves closer during a bow draw; V keeps first person available. Pickup and tool reach remain measured from the traveler.

The clearing now has rolling outer terrain, paths, wind-driven grass, flowers, fuller pines, distant silhouettes, warm sunlight, and atmospheric haze. The bench has a planked top and braces; chests have planks, rivets, and an opening lid; boulders have lichen. The HUD is shorter, with camera and full-screen hints beside the hotbar. These are original procedural prototype assets, ready for further refinement; the detailed concept illustration is the target, not a claim of finished graphics. See `docs/art/WILLOW_SCOUT.md`.

## Start with empty hands

If the game is already running, click the editor's square **Stop** button, then **Run Project** again to load the changes. No new download is needed when using this project folder.

Every background now starts with **eight empty inventory slots and no tools**. Your keepsake stays part of your character identity and does not consume a slot.

1. Walk near fallen sticks and loose stones and press **E** to gather. Pickup assist reaches three meters across a broad area in front of you, including items at your feet, so you can keep looking forward. Direct aim takes priority; otherwise the nearest eligible item is chosen. Solid obstacles block collection. Each starting pile contains two items.
2. Press **I** to see your backpack. Sticks, stones, and wood stack to **10** per slot. A tool occupies one slot.
3. Collect **6 sticks + 4 stones**, then approach the marked **Camp Worksite**, ahead and left of the starting point. Press **E**, or open **I** while standing nearby, and choose **Build simple bench**.
4. At the built bench, spend **3 sticks + 2 stones** on **Craft & equip stone axe**. Starting from scratch, that is nine sticks and six stones total; gathering five stick piles and three stone piles is enough.
5. Close the backpack, walk up to a pine, and click four times to chop it down. Aim at the fallen logs and press **E** to collect five wood into your backpack.
6. Back at the bench, spend **5 wood + 2 sticks** on **Craft storage chest**. Select the chest in your backpack and choose **Place chest here**; it lands on the ground in front of you. Walk up to it and press **E** to move stacks between your pack and its twelve slots. An empty chest can be picked up and moved. A chest within about eight meters of the bench is **connected**: the bench's recipes draw from it after your backpack, and the workbench prompt shows how many chests are connected.

The **Craftables** icon grid shows all eight recipes. Hover an icon to see what it does, materials you have versus need, missing amounts, and any bench or backpack requirement. Click an icon (or focus it with Tab) to keep its details open, then use the separate **Craft** button below. Browsing never spends materials. Dimmed icons remain browsable; READY, OWNED, and BUILT labels show their state. Arrow and stick icons show their batch output counts. Recipes use nearby connected chests too:

| Recipe | Materials | Use |
| --- | --- | --- |
| Woodland bow | 3 wood + 2 sticks | Hold left click to draw, release to fire. Longer draws shoot farther. |
| 5 stone-tipped arrows | 2 sticks + 1 stone | Bow ammunition; landed arrows can be recovered with E. |
| Stone pickaxe | 3 sticks + 4 stones | Four swings break a boulder; each hit drops two loose stones to gather with E. |
| Pine torch | 2 sticks + 1 wood | Hold for warm light. No fuel upkeep or fire damage in this prototype. |
| Split wood into sticks | 1 wood | Produces 4 sticks for tools and camp supplies. |

The bow and tools automatically take the first unused hotbar shortcut when equipped. Shortcuts point to items in your eight-slot backpack; they add no storage. A stored or dropped tool is shown dimmed until recovered. Assignments survive quitting and loading.

The recipe panel shows your current materials, requirements, and whether a craft is available. Crafting spends ingredients only if the complete result fits. When a pickup would exceed capacity, only the amount that fits is collected; the rest stays on the ground.

Select a backpack slot to inspect an item, equip or put away a tool, or **Drop selected stack**. Dropped items can be recovered. Equipped tools still occupy their backpack slots. Axes chop pines; pickaxes mine boulders. Depleted boulders stay depleted after loading.

An **archery target** stands at the far right of the clearing, beyond the rocks. With a bow equipped and arrows in the backpack, hold left click for up to 0.85 seconds, then release. The HUD shows draw strength and arrow count. A quick tap does not shoot; right click, changing equipment, opening a panel, or losing window focus cancels the draw without spending ammunition. The target reports bullseye, inner ring, or target hit. Its practice hit counter resets on entering the clearing.

Each shot consumes one arrow, which becomes a recoverable pickup on impact. Arrows follow gravity, and solid walls block them, including at close range. Flying arrows and landed pickups survive saving and loading. Arrows that leave the test clearing or fly longer than eight seconds are lost. Bow damage against enemies and hunting remain future work; bows cannot chop trees or mine rocks.

Jump with **Space**. Obstacles block axe hits, and chopping only reaches nearby trees. Falling off the test clearing returns you to the starting point with your current inventory.

**Your progress is kept.** Your position and view, backpack, hotbar shortcuts, held tool, the workbench, tree and boulder damage, loose and dropped resources, and every placed chest with its contents are written to `user://save.json`: a moment after anything changes, whenever you close a panel, every 15 seconds while you play, when you press **C**, and when the window closes. The opening screen then offers **Continue your journey**; **Start over** (it asks twice) erases the clearing but keeps your traveler, whose appearance lives in its own file. Recipes never spend anything unless the whole recipe, including its result, fits.

Save format 4 accepts existing format 1, 2, and 3 saves without resetting the clearing. Format 1 saves gain an axe shortcut when an axe is in the backpack; format 2 shortcuts stay intact. Format 3 adds in-flight arrow position, velocity, and age. Format 4 also stores camera mode; older saves start in third person. The added grove pines begin uncut and subsequently save like the original trees. Closing the native game window also saves before quitting; stopping a process from the editor can interrupt it, so use **Save & Quit** to finish a session.

## Verification

Use your Godot executable in these commands:

- `Godot --headless --path . --script res://tests/crafting_icons_test.gd` — eight craftables, hover recipe/use/missing amounts, safe browsing, keyboard focus, explicit build/craft, linked-storage totals, output counts, and grid/detail/tooltip bounds.
- `Godot --headless --path . --script res://tests/third_person_test.gd` — camera switching and wall collision, empty starting gear, third-person gathering/chopping/bow obstruction, animation, terrain collision, saved camera choice, and format 3 migration.
- `Godot --headless --path . --script res://tests/bow_test.gd` — bow/arrow recipes, connected materials, draw strength, cancellation, one-arrow cost, hotbar, gravity, target scoring, close obstruction, E recovery, airborne/landed persistence, and old-save migration.
- `Godot --headless --path . --script res://tests/hotbar_recipes_test.gd` — shortcuts, equip/holster, stored tools, new recipes, mining, torch light, old-save migration, immediate wood rewards, panel bounds, save failures, and the actual Save & Quit button.
- `Godot --headless --path . --script res://tests/pickup_assist_test.gd` — generous pickup targeting, reach limits, priority, and blocked sight lines.
- `Godot --headless --path . --script res://tests/inventory_crafting_test.gd` — slot limits, stacking, partial pickups, atomic crafting, empty-handed start, gathering, workbench, axe, equip/drop/recover.
- `Godot --headless --path . --script res://tests/jump_axe_test.gd` — jumping, landing, axe reach and obstruction, cooldown, felling, wood pickup, mouse resume, and fall recovery after obtaining an axe.
- `Godot --headless --path . --script res://tests/character_creation_test.gd` — character customization, isolated save round trip, world entry, and reopening.
- `Godot --headless --path . --script res://tests/chest_storage_test.gd` — chest inventory rules and transfers, rejected save data, the chest recipe, the placement footprint check, opening with E, store/take, and packing an empty chest up.
- `Godot --headless --path . --script res://tests/connected_storage_test.gd` — crafting across the backpack and chests near the bench: backpack first, distance limit, atomic failure, output in the backpack, the workbench prompt, panel totals, and persistence of chest stock.
- `Godot --headless --path . --script res://tests/save_load_test.gd` — malformed saves, a full snapshot round trip (pose, backpack, axe, bench, trees, pickups, dropped stacks, chests), no duplicated wood, checkpoints on closing panels, C keeping progress, Continue, and Start over.

The inventory test can also run with graphics enabled and `-- --screenshots=/absolute/output/folder` to capture the starting clearing, backpack, and bench. The hotbar test accepts the same screenshot option. Every test uses isolated profile and save paths in the OS temporary folder through `tests/test_paths.gd`, so none touch your character or clearing. On restricted hosts, add `--log-file /absolute/writable/path.log`.

For an isolated visual playground, open `scenes/visual_preview.tscn` and **Run Current Scene** (Command + R on Mac). It supplies temporary tools and a bench/chest, uses temporary saves, and never edits your real traveler or clearing. O toggles a front portrait; P captures the viewport into the temporary test folder and prints the path and current frame rate. Use **Run Project** afterward to return to the real game.

## First milestone

Keep the backpack and crafting loop small. Skills, NPCs, weather, and procedural generation remain deferred.

The first gameplay milestone is:

> Walk into a stylized forest, interact with one tree/resource, collect something, and return it to a visible home/workshop area.

Once that feels decent, expand one system at a time.

## Working with assistants

`AGENTS.md` is the shared working agreement for Claude Code and ChatGPT/Codex sessions (start and end checklists, identity, lanes, conventions), and `docs/STATUS.md` is the handoff log each session updates.

## Repository layout

- `scenes/` — Godot scenes
- `scripts/` — GDScript gameplay code
- `assets/` — models, textures, audio, etc.
- `docs/` — design notes and roadmap

See `docs/DESIGN_BRIEF.md` and `docs/ROADMAP.md` for the current plan.
