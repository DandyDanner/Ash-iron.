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
- Left click — swing the starter axe (while the mouse is captured)
- `E` — collect a wood bundle while aiming at it
- `Esc` — release mouse
- Click game window — capture mouse again
- `C` — return to character creation (re-entering resets the test clearing)

## Run it

1. Install the current stable Godot 4 release for Apple Silicon.
2. Open `project.godot` in Godot.
3. Press **F5** or the **Run Project** button in the top-right. On some Mac keyboards use **Fn + F5**.
4. Create your traveler, then enter the tiny placeholder 3D test area.

Your name and appearance are saved locally between launches. They are separate from future gameplay save data. The character is an original procedural art blockout, ready for feedback before investing in a finished model. See `docs/CHARACTER_CREATION.md` for the current feature set.

## Try jumping and chopping

If the game is already running, stop it with the editor's square **Stop** button, then press **Run Project** again to load the changes. No new download is needed when using this project folder.

After entering the clearing, walk toward the pine directly ahead. Press **Space** to jump. Get close enough to see the chopping prompt, aim the crosshair at the trunk, and click four times. Each full axe swing deals one hit. When the tree falls, look down at the bundled logs and press **E** to collect five wood. The wood total appears at the upper left.

The axe starts equipped for every background. It has a visible swing, contact feedback, wood chips, and simple swing/impact sounds. Obstacles block hits, and chopping only reaches nearby trees. Falling off the test clearing returns you to the starting point.

Wood and harvested trees currently reset when restarting the clearing or returning through character creation. Persistent inventory, home drop-off, and a bow are future work.

Gameplay verification: run `Godot --headless --path . --script res://tests/jump_axe_test.gd` using your Godot executable. This covers jumping and landing, preventing double jumps, axe reach, blocked hits, swing cooldown, tree felling, one-time pickup, resuming mouse capture, and recovery after falling off the map.

## First milestone

Do **not** start with inventory, skills, NPCs, weather, or procedural generation.

The first gameplay milestone is:

> Walk into a stylized forest, interact with one tree/resource, collect something, and return it to a visible home/workshop area.

Once that feels decent, expand one system at a time.

## Repository layout

- `scenes/` — Godot scenes
- `scripts/` — GDScript gameplay code
- `assets/` — models, textures, audio, etc.
- `docs/` — design notes and roadmap

See `docs/DESIGN_BRIEF.md` and `docs/ROADMAP.md` for the current plan.
