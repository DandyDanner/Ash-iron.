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
- Use the **Traveler** dropdown to choose **Willow Scout**, **Hearthland Ranger**, **Ridge Wayfarer**, or **Ember Forager**. These use the Blender models with fixed outfits/hair. **Custom Scout (original)** restores the original build, face, hair, and color controls.
- Press **C** in the clearing to change travelers, then **Continue your journey**. Your inventory, placed furniture, and world progress are kept. Existing profiles retain their original look until you choose a new traveler.
- Travelers, backgrounds and keepsakes are cosmetic. Classes and abilities are deferred.
- `W A S D` — move
- `Shift` — sprint
- `Space` — jump
- Mouse — look / orbit the traveler while standing still
- `V` — switch third person / first person; the choice is saved
- `F11` — toggle full screen in a standalone game window (some Mac keyboards need Fn)
- Left click — swing your equipped axe, or your pickaxe at boulders and iron veins; thrust with a spear; with a bow, hold to draw and release to fire (while the mouse is captured)
- Right click — cancel a bow draw without spending an arrow
- `E` — gather sticks, loose stones, wood, or ore; use a placed workbench; open a storage chest; use a furnace
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

Your name and appearance are saved locally between launches. They are separate from the clearing save. The four Blender travelers now have playable skinned exports; the original procedural customization remains available. These are still prototype models with further art and animation work ahead. See `docs/CHARACTER_CREATION.md` for the current feature set.

## Character modeling in Blender

Blender 5.2.1 LTS is installed. Open `art/blender/cycles/cycle_30/characters.blend` for the latest Willow Scout alongside all other preserved traveler and wildlife studies. Thirty saved modeling/render/review cycles and their actual images are documented in [the art review](art/blender/cycles/REVIEW.md). The latest four cycles focus only on Willow’s facial planes, eyes, profile and swept hair; see the [matched before/after review](docs/art/WILLOW_FOCUSED_REVIEW.md). The native studies remain preserved and unrigged. The four travelers now have separate skinned game exports in `assets/characters/`, driven by the existing walking, jumping and equipment poses. Wildlife studies remain offline; the clearing is unchanged by this integration. The original prototype baseline remains in `art/blender/ash_iron_character_studio.blend`. See [the morning review](docs/art/OVERNIGHT_REVIEW.md) for actual model images and `art/blender/README.md` for reproduction and integration limits.

## Coordinated visual pass

The approved **Willow Scout** guides the shared character model: a short sage cape, cream sleeves, teal sash, leather pouches, and folded boots. The four authored presets retain their modeled appearance; saved skin, hair, build and clothing choices remain available under Custom Scout. Keepsakes and backgrounds apply to every traveler. Walking, sprinting, jumping, chopping, and drawing the bow move the articulated body. A spring-arm camera retracts near solid obstacles and moves closer during a bow draw; V keeps first person available. Pickup and tool reach remain measured from the traveler. The stone pickaxe has a faceted hooked point, a shorter rear chisel, a lashed socket, and a wrapped wooden handle; held tools, dropped pickups, and inventory icons share that design. The axe and pickaxe lift back and strike forward/down in a vertical plane in both camera views, with a windup and follow-through. The woodland bow has curved, tapered limbs, a wrapped palm grip, an upright hold, and a drawing hand that follows the string; the arrow rests above the grip.

The scout and boar now have a focused model refinement pass: smoother shaped surfaces, swept hair and defined eyelids/lips, cape embroidery and a folded hood, and curved tusks with layered boar fur. These are still simplified procedural assets; the concept illustrations remain the target for future sculpted/textured models. This pass does not change the world.

The clearing now has rolling outer terrain, paths, wind-driven grass, flowers, fuller pines, distant silhouettes, warm sunlight, and atmospheric haze. The bench has a planked top and braces; chests have planks, rivets, and an opening lid; boulders have lichen. The HUD is shorter, with camera and full-screen hints beside the hotbar. These are original procedural prototype assets, ready for further refinement; the detailed concept illustration is the target, not a claim of finished graphics. See `docs/art/WILLOW_SCOUT.md`.

## Start with empty hands

If the game is already running, click the editor's square **Stop** button, then **Run Project** again to load the changes. No new download is needed when using this project folder.

Every background now starts with **eight empty inventory slots and no tools**. Your keepsake stays part of your character identity and does not consume a slot.

1. Walk near fallen sticks and loose stones and press **E** to gather. Pickup assist reaches three meters across a broad area in front of you, including items at your feet, so you can keep looking forward. Direct aim takes priority; otherwise the nearest eligible item is chosen. Solid obstacles block collection. Each starting pile contains two items.
2. Press **I** to see your backpack. Sticks, stones, and wood stack to **10** per slot. A tool occupies one slot.
3. Collect **6 sticks + 4 stones**. Open **I** anywhere, select the workbench icon under **Craftables**, and click **Craft workbench**. It goes into your backpack and uses one slot. Face a clear, level spot, select the bench in your backpack, and click **Place workbench here**. It appears in front of you, facing the same direction. No marked campsite is required.
4. At the built bench, spend **3 sticks + 2 stones** on **Craft & equip stone axe**. Starting from scratch, that is nine sticks and six stones total; gathering five stick piles and three stone piles is enough.
5. Close the backpack, walk up to a pine, and click four times to chop it down. Aim at the fallen logs and press **E** to collect five wood into your backpack.
6. Back at the bench, spend **5 wood + 2 sticks** on **Craft storage chest**. Select the chest in your backpack and choose **Place chest here**; it lands on the ground in front of you. Walk up to it and press **E** to move stacks between your pack and its twelve slots. An empty chest can be picked up and moved. A chest within about eight meters of the bench is **connected**: the bench's recipes draw from it after your backpack, and the workbench prompt shows how many chests are connected.
7. Take your pickaxe to a rusty **iron vein**. Three sit at the edges of the clearing: north-east beyond the archery target, east past the first pine, and south-west of camp. Four strikes free four **iron ore**, and ordinary boulders sometimes shed a chunk as well. Back at the bench, spend **10 stones + 2 wood** on **Craft stone furnace**, place it like a chest, then press **E** at it to load ore and wood. A furnace automatically draws **wood and ore from chests within 8 meters of the furnace**. It reserves only the next complete batch, leaving other supplies in storage. Its panel shows connected chests and lets you turn auto-feed off; manual Load buttons use your backpack first, then connected chests. Two ore and one wood become an **iron ingot** every twelve seconds while you do other things; take the ingots from the same panel, and pack the furnace up when it is empty. Ingots have no recipes yet: iron tools and weapons are the next milestone.

You can have multiple workbenches. Stand close and press **E** to use a particular bench; opening **I** uses the nearest reachable one. Tool recipes still require a placed bench. **Pick up this workbench** returns it to an empty backpack slot so you can move camp; its connected chests stay in place with their contents. Hand crafting can use nearby linked stock while at a bench, but cannot draw from distant chests.

Benches, chests, and furnaces require clear, level ground beneath their whole footprint. Placement rejects obstacles, overlapping furniture, ledges, steep/uneven ground, and placing through walls. Failed crafting, placement, or packing never consumes the item or ingredients.

The **Craftables** icon grid shows all eleven recipes. Hover an icon to see what it does, materials you have versus need, missing amounts, and any bench or backpack requirement. Click an icon (or focus it with Tab) to keep its details open, then use the separate **Craft** button below. Browsing never spends materials. Dimmed icons remain browsable; READY, UNAVAILABLE, OWNED, and FITTED labels show their state. Arrow and stick icons show their batch output counts. Recipes use nearby connected chests too:

| Recipe | Materials | Use |
| --- | --- | --- |
| Explorer Pack | 1 Bellmaw hide + 2 wood + 4 sticks | Permanent eight-to-twelve-slot upgrade at the bench. Fits immediately, takes no slot, and works with a full pack. |
| Stone spear | 2 wood + 2 stones | Left click for a forward thrust. Practice within 2.8 meters of the target. |
| Woodland bow | 3 wood + 2 sticks | Hold left click to draw, release to fire. Longer draws shoot farther. |
| 5 stone-tipped arrows | 2 sticks + 1 stone | Bow ammunition; landed arrows can be recovered with E. |
| Stone pickaxe | 3 sticks + 4 stones | Four swings break a boulder; each hit drops two loose stones to gather with E. |
| Pine torch | 2 sticks + 1 wood | Hold for warm light. No fuel upkeep or fire damage in this prototype. |
| Split wood into sticks | 1 wood | Produces 4 sticks for tools and camp supplies. |
| Stone furnace | 10 stones + 2 wood | Placeable smelter. Two iron ore + one wood become one iron ingot every twelve seconds; it keeps working while you are away. |

The spear, bow, and tools automatically take the first unused hotbar shortcut when equipped. Shortcuts point to items in your backpack (eight slots, or twelve after the Explorer Pack upgrade); they add no storage. A stored or dropped tool is shown dimmed until recovered. Assignments survive quitting and loading.

The recipe panel shows your current materials, requirements, and whether a craft is available. Crafting spends ingredients only if the complete result fits. When a pickup would exceed capacity, only the amount that fits is collected; the rest stays on the ground.

Select a backpack slot to inspect an item, equip or put away a tool, or **Drop selected stack**. Dropped items can be recovered. Equipped tools still occupy their backpack slots. Axes chop pines and can also hit enemies for **10 base damage**, half the spear’s **20**. Bellmaw’s thick hide halves either hit outside its recovery window. Equip the axe from your hotbar and left-click to swing; each swing hits once at contact, within 2.6 meters, and solid obstacles block it. It works as a backup against both Bristleback and Bellmaw. Durability and weapon breakage are not implemented yet. Pickaxes mine boulders and iron veins. Mined stone and ore fragments fall onto terrain instead of hovering on the player’s collision shape. Existing floating stone/ore pickups also settle after loading. Depleted boulders and worked-out veins stay that way after loading.

An **archery target** stands at the far right of the clearing, beyond the rocks. With a bow equipped and arrows in the backpack, hold left click for up to 0.85 seconds, then release. The HUD shows draw strength and arrow count. A quick tap does not shoot; right click, changing equipment, opening a panel, or losing window focus cancels the draw without spending ammunition. The target reports bullseye, inner ring, or target hit. Its practice hit counter resets on entering the clearing.

Each shot consumes one arrow, which becomes a recoverable pickup on impact. Arrows follow gravity, and solid walls block them, including at close range. Flying arrows and landed pickups survive saving and loading. Arrows that leave the test clearing or fly longer than eight seconds are lost. Arrows deal 25 damage to the Bristleback Boar; bows cannot chop trees or mine rocks.

Jump with **Space**. Obstacles block axe hits, and chopping only reaches nearby trees. Falling off the test clearing returns you to the starting point with your current inventory.

**Your progress is kept.** Your health, the boar’s and Bellmaw’s health and defeat, the Explorer Pack upgrade, your position and view, backpack, hotbar shortcuts, held tool, the workbench, tree, boulder, and iron vein damage, loose and dropped resources, every placed chest with its contents, and every furnace with its ore, wood, ingots, and smelting progress are written to `user://save.json`: a moment after anything changes, whenever you close a panel, every 15 seconds while you play, when you press **C**, and when the window closes. The opening screen then offers **Continue your journey**; **Start over** (it asks twice) erases the clearing but keeps your traveler, whose appearance lives in its own file. Recipes never spend anything unless the whole recipe, including its result, fits.

Save format 9 accepts existing format 1 through 8 saves without resetting the clearing. Format 1 saves gain an axe shortcut when an axe is in the backpack; format 2 shortcuts stay intact. Format 3 adds in-flight arrow position, velocity, and age. Format 4 also stores camera mode; older saves start in third person. Format 5 stores every placed workbench with its position and rotation. An older built camp bench becomes a movable bench at its original location; an unbuilt worksite disappears without granting a free bench. Format 6 adds traveler and boar health; older saves keep their progress and gain a healthy boar and full traveler health. A defeated boar’s hide persists without duplicating; format 9 adds its respawn countdown. Format 7 adds iron vein damage and placed furnaces; older saves start with fresh veins and no furnace. Format 8 adds Bellmaw health/defeat and the permanent Explorer Pack flag. Older saves keep eight slots and receive a fresh Bellmaw, fresh Echo Hollow pines and an unmined lookout vein. Bellmaw resumes at its home position with saved health and a new warning before it can attack; its saved hide does not duplicate. The added grove pines begin uncut and subsequently save like the original trees. Format 9 stores both enemy respawn countdowns and each furnace’s auto-feed switch. Older defeated enemies start a two-minute countdown; old Bellmaw health is scaled from 80 to 160 while preserving its health percentage. Existing furnaces gain auto-feed and keep their stored materials, ingots and percentage progress at the new twelve-second rate. Closing the native game window also saves before quitting; stopping a process from the editor can interrupt it, so use **Save & Quit** to finish a session.

## Stone spear and the Bristleback Boar

Craft a **stone spear** at a nearby workbench using **2 wood + 2 stones**. Connected chests can supply the materials. It takes one backpack slot, equips after crafting, and uses the first available hotbar shortcut. Left click to thrust; each attack can land one hit within 2.8 meters. Solid obstacles block the strike. Test it on the practice target at the far right of the clearing. The spear does not chop trees or mine rocks.

The first enemy is the **Bristleback Boar**, a russet animal with a dark mane and curved tusks in the back-left grove (left and forward from the starting camp, around x = -15, z = -13). It notices you within eight meters when it can see you. It approaches, lowers its head and paws the ground for a one-second warning, then commits to a straight charge. Sidestep with A/D, turn toward it, and strike during its recovery. Trees and rocks stop charges. It returns home when you leave its territory, restoring its health; the starting camp is safe.

The boar has **60 health**: three spear hits (20 each) or three arrows (25 each) defeat it. Each charge deals 25 of your 100 health. Opening a panel or losing focus pauses its behavior. Defeat returns you to the starting camp with full health and all your belongings. Resting near that starting point restores health gradually after eight seconds without damage. This is an approachable first combat prototype, with no dropped death bag or stamina system yet.

Defeating the boar leaves **one boar hide** to gather with E. It stacks to ten and can be stored or dropped; leather recipes will come later. Both the boar and Bellmaw respawn **two minutes of active play after defeat**, once you are at least **8 meters from their home** and the spawn space is clear. Menus/focus loss pause the timer; saving and quitting preserves the remaining time, with no offline countdown. Each new defeat drops one hide; old loose hides remain collectible. The approved wildlife art direction and later progression are recorded in `docs/art/BRISTLEBACK.md`. Ore, the furnace, and ingots are in; the next progression milestone is **an iron weapon upgrade** made from ingots.

## Echo Hollow and the Explorer Pack

Take your spear or bow past the **archery target on the right side of camp**. An **ECHO HOLLOW →** sign and ochre markers lead east to the new outer clearing (x = 42, z = -20). The path continues to the **Old Lookout** with another iron vein and harvestable grove pines. This adds a small destination on the existing outer terrain; the starting supplies and camp remain intact.

The **Bellmaw** has a broad, four-legged body and an amber throat that swells before its attack. It plants its feet for a **1.2-second warning**, then booms once inside the visible **4.5-meter ring**. Back outside the ring or put solid rock cover between you and it. Strike during its **1.25-second recovery**. It has **160 health** and approaches at **3.3 m/s**. During recovery it takes **20 spear / 10 axe / 15 arrow damage**; its thick hide halves incoming damage at all other times (rounded down). The boom deals **34 damage**, enough for three hits to defeat a fully healthy traveler. Eight perfectly timed spear hits can win; attacks against its guarded hide take sixteen. Watch for **SOFT THROAT — strike now!** after the boom. It returns home and heals when you leave its territory. Panels/focus loss pause it. This daytime prototype does not require a night cycle or lantern.

Defeat it and gather **one Bellmaw hide with E**. At your workbench, open **I → Pack +4** and craft with **1 Bellmaw hide + 2 wood + 4 sticks** (nearby chests count). It permanently fits the **Explorer Pack**, expanding your backpack from **8 to 12 slots**. No spare slot is required. Scroll down in the pack grid to see slots 9–12; chest transfers, dropping, tool shortcuts and placement work from those slots. The upgrade and contents save. The existing character backpack appearance is unchanged in this first capacity upgrade. Bellmaw uses the same two-minute respawn rule as the boar, so you can return to practice.

The [latest actual graphics review](docs/art/SURVIVAL_REFINEMENT_REVIEW.md) shows rebuilt first-person hands, subtler traveler surface materials, finer boar fur/cloven hooves and Bellmaw body/face refinements. These remain prototype models; the traveler face geometry has not been resculpted in this pass.

The [concept sheet](docs/art/bellmaw-concept-v1.png) is an art target; [actual Godot captures and limits](docs/art/ECHO_HOLLOW_REVIEW.md) show the simpler playable model. Bellmaw and **Threadwing** remain in the [creature direction](docs/CREATURE_DIRECTION.md). Armor, XP levels, larger biomes and the Wayfarer's Lantern are future work.

## Verification

For visual gear checks, run `scenes/visual_preview.tscn` as the current scene (Command + R on Mac). Press O for portrait mode; J cycles axe carry/windup/contact/follow-through (U does the same for the pickaxe; T for the spear), K shows a drawn bow, and L orbits the camera. The J/U/T pose controls also work in first person. O enters/exits portrait mode and returns to play. B starts an isolated boar encounter with the spear; N shows its portrait. This scene uses temporary inventory and saves. Run Project returns to the regular game.

For reproducible actual-model images, run `Godot --path . --script res://tests/art_portrait.gd -- --output=/absolute/output/folder` with graphics enabled. It renders scout front/back/face, the boar, and both in the existing clearing, using isolated temporary saves. The neutral studio lighting belongs only to this utility.

Use your Godot executable in these commands (twenty suites):

- `Godot --headless --path . --script res://tests/traveler_selection_test.gd` — all four previews and skins, menu selection, profile migration, movement, held equipment, and continuing with inventory intact. Add `-- --screenshots=/absolute/existing/folder` with graphics enabled to capture each traveler in the creator and clearing.

- `Godot --headless --path . --script res://tests/boar_test.gd` — warning, sidestep, charge/recovery, pause, walls, territory, actual spear/bow hits, one hide reward, player defeat/healing, persistence, and format 5 migration.
- `Godot --headless --path . --script res://tests/spear_test.gd` — spear recipe and connected storage, full-pack failure, both camera views, single contact, reach/obstruction, cancellation, non-harvesting, hand/body clearance, hotbar, storage, save/load, and dropped recovery.
- `Godot --headless --path . --script res://tests/placeable_workbench_test.gd` — hand crafting, placement/obstruction/overlap/slope checks, selected bench and linked storage, packing and relocation, multiple-bench snapshots, older saves, and dropped bench recovery.
- `Godot --headless --path . --script res://tests/crafting_icons_test.gd` — eleven craftables, hover recipe/use/missing amounts, safe browsing, keyboard focus, explicit build/craft, linked-storage totals, output counts, and grid/detail/tooltip bounds.
- `Godot --headless --path . --script res://tests/third_person_test.gd` — camera switching and wall collision, empty starting gear, third-person gathering/chopping/bow obstruction, animation, tool/forearm clearance, axe cutting direction, upright bow and hand/string/arrow alignment, terrain collision, saved camera choice, and format 3 migration.
- `Godot --headless --path . --script res://tests/bow_test.gd` — bow/arrow recipes, connected materials, draw strength, cancellation, one-arrow cost, hotbar, gravity, target scoring, close obstruction, E recovery, airborne/landed persistence, and old-save migration.
- `Godot --headless --path . --script res://tests/hotbar_recipes_test.gd` — shortcuts, equip/holster, stored tools, new recipes, mining, torch light, old-save migration, immediate wood rewards, panel bounds, save failures, and the actual Save & Quit button.
- `Godot --headless --path . --script res://tests/pickup_assist_test.gd` — generous pickup targeting, reach limits, priority, and blocked sight lines.
- `Godot --headless --path . --script res://tests/inventory_crafting_test.gd` — slot limits, stacking, partial pickups, atomic crafting, empty-handed start, gathering, workbench, axe, equip/drop/recover.
- `Godot --headless --path . --script res://tests/jump_axe_test.gd` — jumping, landing, forward axe/pickaxe swing paths, axe reach and obstruction, cooldown, felling, wood pickup, mouse resume, and fall recovery after obtaining an axe.
- `Godot --headless --path . --script res://tests/character_creation_test.gd` — character customization, isolated save round trip, world entry, and reopening.
- `Godot --headless --path . --script res://tests/chest_storage_test.gd` — chest inventory rules and transfers, rejected save data, the chest recipe, the placement footprint check, opening with E, store/take, and packing an empty chest up.
- `Godot --headless --path . --script res://tests/connected_storage_test.gd` — crafting across the backpack and chests near the bench: backpack first, distance limit, atomic failure, output in the backpack, the workbench prompt, panel totals, and persistence of chest stock.
- `Godot --headless --path . --script res://tests/iron_furnace_test.gd` — iron veins that need a pickaxe and free four ore, the boulder ore chance, the furnace recipe and placement, opening with E, loading ore and wood, timed smelting with carried progress and stopping, taking ingots, persistence of furnaces and veins, format 6 saves, and packing up.
- `Godot --headless --path . --script res://tests/save_load_test.gd` — malformed saves, a full snapshot round trip (pose, backpack, axe, bench, trees, pickups, dropped stacks, chests), no duplicated wood, checkpoints on closing panels, C keeping progress, Continue, and Start over.

- `Godot --headless --path . --script res://tests/axe_combat_test.gd` — axe hits both enemies in both views, 10 versus 20 spear damage, contact timing, reach/solid cover, cancellation, no pickaxe combat damage, and normal kill rewards.
- `Godot --headless --path . --script res://tests/echo_hollow_test.gd` — route ground, warning, radius, cover, pause, recovery/leash, real spear/arrow hits, one hide and persistence.
- `Godot --headless --path . --script res://tests/explorer_pack_test.gd` — workbench/linked costs, full-pack fitting, capacity, scrollable final slot, drop/transfer, hotbar, save and version 7 migration.

- `Godot --headless --path . --script res://tests/survival_refinement_test.gd` — guarded/recovery damage, respawn delay/pause/clearance/persistence, falling mining drops, furnace chest range/atomic feed/output cap/12-second timing/toggle save, first-person grips and format 8 migration.

For native hand/Bellmaw/furnace captures, run `Godot --path . --script res://tests/refinement_preview.gd -- --output=/absolute/output/folder`. It uses isolated saves and closes its own window.

For native Echo Hollow captures, run `Godot --path . --script res://tests/echo_preview.gd`. It uses an isolated temporary profile/world, captures the actual creature, warning and pack UI under the OS temporary `ash-iron-tests` folder, then closes its own window.

The inventory test can also run with graphics enabled and `-- --screenshots=/absolute/output/folder` to capture the starting clearing, backpack, and bench. The hotbar test accepts the same screenshot option. Every test uses isolated profile and save paths in the OS temporary folder through `tests/test_paths.gd`, so none touch your character or clearing. On restricted hosts, add `--log-file /absolute/writable/path.log`.

For an isolated visual playground, open `scenes/visual_preview.tscn` and **Run Current Scene** (Command + R on Mac). It supplies temporary tools, six sticks, four stones, and a bench/chest fixture, uses temporary saves, and never edits your real traveler or clearing. O toggles a front portrait; P captures the viewport into the temporary test folder and prints the path and current frame rate. Use **Run Project** afterward to return to the real game.

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
