# Ash & Iron

Working repository for a stylized frontier crafting-survival adventure.

## Current goal

Build a small, playable Godot prototype before expanding the design. Prototype 0.1 should prove that moving through the wilderness, gathering resources, returning home, and progressing feels good.

## Design pillars

- First-person exploration and combat
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
- Mouse — look
- Left click — swing your crafted and equipped axe (while the mouse is captured)
- `E` — gather sticks, loose stones, or wood; use the camp worksite or bench; open a storage chest
- `I` — open or close your backpack and crafting panel
- `Esc` — release mouse
- Click game window — capture mouse again
- `C` — return to character creation (your progress is saved first)
- Progress in the clearing saves itself; **Save game** in the backpack saves on demand

## Run it

1. Install the current stable Godot 4 release for Apple Silicon.
2. Open `project.godot` in Godot.
3. Press **F5** or the **Run Project** button in the top-right. On some Mac keyboards use **Fn + F5**.
4. Create your traveler, then enter the tiny placeholder 3D test area.

Your name and appearance are saved locally between launches. They are separate from future gameplay save data. The character is an original procedural art blockout, ready for feedback before investing in a finished model. See `docs/CHARACTER_CREATION.md` for the current feature set.

## Start with empty hands

If the game is already running, click the editor's square **Stop** button, then **Run Project** again to load the changes. No new download is needed when using this project folder.

Every background now starts with **eight empty inventory slots and no tools**. Your keepsake stays part of your character identity and does not consume a slot.

1. Walk near fallen sticks and loose stones and press **E** to gather. Pickup assist reaches three meters across a broad area in front of you, including items at your feet, so you can keep looking forward. Direct aim takes priority; otherwise the nearest eligible item is chosen. Solid obstacles block collection. Each starting pile contains two items.
2. Press **I** to see your backpack. Sticks, stones, and wood stack to **10** per slot. A tool occupies one slot.
3. Collect **6 sticks + 4 stones**, then approach the marked **Camp Worksite**, ahead and left of the starting point. Press **E**, or open **I** while standing nearby, and choose **Build simple bench**.
4. At the built bench, spend **3 sticks + 2 stones** on **Craft & equip stone axe**. Starting from scratch, that is nine sticks and six stones total; gathering five stick piles and three stone piles is enough.
5. Close the backpack, walk up to a pine, and click four times to chop it down. Aim at the fallen logs and press **E** to collect five wood into your backpack.
6. Back at the bench, spend **5 wood + 2 sticks** on **Craft storage chest**. Select the chest in your backpack and choose **Place chest here**; it lands on the ground in front of you. Walk up to it and press **E** to move stacks between your pack and its twelve slots. An empty chest can be picked up and moved.

The recipe panel shows your current materials, requirements, and whether a craft is available. Crafting spends ingredients only if the complete result fits. When a pickup would exceed capacity, only the amount that fits is collected; the rest stays on the ground.

Select a backpack slot to inspect an item, equip or put away the axe, or **Drop selected stack**. Dropped items can be recovered. The equipped axe still occupies its backpack slot. Large boulders are solid scenery for now; gather the loose stones around them by hand.

Jump with **Space**. Obstacles block axe hits, and chopping only reaches nearby trees. Falling off the test clearing returns you to the starting point with your current inventory.

**Your progress is kept.** Your position and view, backpack, equipped axe, the workbench, tree damage, loose and dropped resources, and every placed chest with its contents are written to `user://save.json`: a moment after anything changes, whenever you close a panel, every 15 seconds while you play, when you press **C**, and when the window closes. The opening screen then offers **Continue your journey**; **Start over** (it asks twice) erases the clearing but keeps your traveler, whose appearance lives in its own file. Crafting straight from chest contents is a later milestone.

## Verification

Use your Godot executable in these commands:

- `Godot --headless --path . --script res://tests/inventory_crafting_test.gd` — slot limits, stacking, partial pickups, atomic crafting, empty-handed start, gathering, workbench, axe, equip/drop/recover.
- `Godot --headless --path . --script res://tests/jump_axe_test.gd` — jumping, landing, axe reach and obstruction, cooldown, felling, wood pickup, mouse resume, and fall recovery after obtaining an axe.
- `Godot --headless --path . --script res://tests/character_creation_test.gd` — character customization, isolated save round trip, world entry, and reopening.
- `Godot --headless --path . --script res://tests/chest_storage_test.gd` — chest inventory rules and transfers, rejected save data, the chest recipe, the placement footprint check, opening with E, store/take, and packing an empty chest up.
- `Godot --headless --path . --script res://tests/save_load_test.gd` — malformed saves, a full snapshot round trip (pose, backpack, axe, bench, trees, pickups, dropped stacks, chests), no duplicated wood, checkpoints on closing panels, C keeping progress, Continue, and Start over.

The inventory test can also run with graphics enabled and `-- --screenshots=/absolute/output/folder` to capture the starting clearing, backpack, and bench. Every test uses its own profile and save paths, so none of them touch your character or your clearing.

## First milestone

Keep the backpack and crafting loop small. Skills, NPCs, weather, and procedural generation remain deferred.

The first gameplay milestone is:

> Walk into a stylized forest, interact with one tree/resource, collect something, and return it to a visible home/workshop area.

Once that feels decent, expand one system at a time.

## Repository layout

- `scenes/` — Godot scenes
- `scripts/` — GDScript gameplay code
- `assets/` — models, textures, audio, etc.
- `docs/` — design notes and roadmap

See `docs/DESIGN_BRIEF.md` and `docs/ROADMAP.md` for the current plan.
