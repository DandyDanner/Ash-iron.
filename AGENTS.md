# Working agreement for Ash & Iron

Two assistants work on this repository, one at a time: **Claude Code** (systems, gameplay rules, saves, tests) and **ChatGPT / Astra with Codex** (visuals, models, materials, lighting, UI polish). Dallon switches between them. This file is the contract that keeps those handoffs clean. Read it before touching anything. `CLAUDE.md` points here so both assistants load the same rules.

## Start of every session

1. Read `docs/STATUS.md`. It says what the last session did, what is half-done, and what is next.
2. Check the working copy:

   ```
   git fetch origin && git status -sb
   ```

   You must be on `main`, clean, and even with `origin/main`. If the tree is dirty or the branch has diverged, stop and ask Dallon which side wins. Never `git reset --hard`, rebase, or force-push on your own.
3. One assistant per working copy at a time. If files change underneath you that you did not edit, another session is active in the same folder: stop, tell Dallon, and move your own work to a separate `git worktree` on its own branch rather than editing side by side. Never revert files you did not change.
4. Confirm the commit identity (the machine's git config pins it for every DandyDanner repository):

   ```
   git var GIT_AUTHOR_IDENT
   ```

   It must read `DandyDanner <315579432+DandyDanner@users.noreply.github.com>`. This is a personal project; the business GitHub account must never appear in it. A pre-push guard rejects any other identity. Fix a wrong commit with `git commit --amend --no-edit --reset-author`.

## End of every session

1. Run the whole test suite with the local Godot binary (`/Users/dallonanderson/Downloads/Godot.app/Contents/MacOS/Godot`; the per-test commands are in `README.md` under Verification). Every test must pass. If a change needs a test updated, update it in the same commit.
2. Add an entry to `docs/STATUS.md` and refresh its "Now" section.
3. Update `README.md` and `docs/ROADMAP.md` when behaviour, controls, or milestones change.
4. Commit with a message that says what changed, then push to `origin main`. Leave nothing uncommitted. Small complete commits beat one large one.

## Lanes

- **Visuals (ChatGPT / Astra):** procedural art and materials in `scripts/traveler_model.gd`, the art inside `storage_chest.gd`, `harvest_tree.gd`, `workbench.gd`, `field_boulder.gd`, `resource_pickup.gd`, `wood_bundle.gd`, and `starter_axe.gd`; lighting, sky, and environment in `scenes/main.tscn` and the character stage in `character_creator.gd`; panel styling in `scripts/panel_base.gd`; icons in `scripts/item_icon.gd`; anything under `assets/`.
- **Systems (Claude Code):** `inventory.gd`, `world.gd`, `game_save.gd`, `storage_panel.gd`, the logic in `player.gd`, crafting rules, and `tests/`.
- Anyone may touch anything, with three rules: keep the tests green; keep the names the tests rely on (nodes `Player`, `PracticePine`, `Tree1`..`Tree3`, `ClearingResources/stick_N`, `ClearingResources/stone_N`, and the groups `workbenches`, `chests`, `pickups`, `wood_bundles`, `harvest_trees`); and when the save format changes, bump `GameSave.VERSION` and decide what happens to old saves.

## Conventions

- Godot 4.7, GDScript with tabs and typed variables. Placeholder art is built procedurally with the static helpers in `traveler_model.gd` so it can be replaced by real assets later without changing gameplay code.
- Original content only: no paid or licensed assets in the repository, no copied text.
- Tests are headless `SceneTree` scripts in `tests/`. Each one sets its own `Profile.storage_path` and `GameSave.storage_path` using `tests/test_paths.gd` in the OS temporary folder, so a test never reads or writes the player's real traveler or clearing. Do the same in any new test.
- Save files live in Godot's user folder as `user://character.json` (appearance) and `user://save.json` (world progress). They stay separate.
- New features should pass the three questions in `docs/ROADMAP.md`, and the design pillars in `docs/DESIGN_BRIEF.md` decide ties.
