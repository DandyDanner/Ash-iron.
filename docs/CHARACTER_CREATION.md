# Traveler creation — first playable version

The player makes a traveler at the edge of the woods, chooses a little history, and brings one meaningful object from home.

## Try it

Import `project.godot` in Godot, then use **Run Project / F5**. The opening screen has three sections:

1. **Your story:** Trapper, Apprentice, Wanderer, or Prospector. Each has a short background and a distinct outfit detail.
2. **Make it yours:** choose one of the four modeled travelers, or Custom Scout (original) for editable build, face, hair and colors. Name, background and keepsake work with every choice. Turn the portrait with the slider or switch between face and outfit framing.
3. **Something from home:** carved fox, worn compass, family scarf, or old journal, each with a short memory and a visible outfit detail.

Choose **Begin your journey** to enter the clearing in third person (V switches to first person). Sleeves and hands reflect the chosen colors; the HUD shows the name, background, and keepsake. Press **C** to edit again; your progress in the clearing is saved first and restored when you continue. Once a saved clearing exists the main button reads **Continue your journey**, and **Start over** (it asks twice) erases the clearing while keeping your traveler.

Changing backgrounds preserves all personal appearance choices, name, and keepsake. An empty name becomes “Traveler.” One local character is saved as `user://character.json`, using a temporary file followed by a rename. Invalid or missing data falls back to a safe default. A failed save keeps the creator open and displays an error. The creator opens on each launch with the saved choices preselected.

## Art and scope

The four traveler presets use colored, skinned figures from the supplied Rodin model. They share the existing movement and equipment animation system, including breathing, walking/jumping poses and tool gestures. Custom Scout retains the original procedural appearance controls. These are prototype skins with painted eyes and fused source clothing/equipment; see [the Rodin party review](art/RODIN_PARTY_REVIEW.md) for actual game captures and remaining work.

Backgrounds have **no stat bonuses, classes, abilities, or resource advantages**. These remain a future design decision. Keepsakes are cosmetic identity data, not usable inventory items yet. A cabin mirror, inventory portrait, cabin display, and expanded equipment customization remain future features.

The existing design brief and wilderness test scene remain the foundation for subsequent gameplay work.

## Verification

Run `Godot --headless --path . --script res://tests/character_creation_test.gd` with your Godot executable. This uses an isolated temporary profile, checks malformed data recovery, cycles every appearance option, verifies backgrounds preserve personalization, activates the Begin button, checks world identity and hands, and reopens the creator with the saved profile. It does not replace the player's saved character.

The same test can run with graphics enabled and `-- --screenshots=/absolute/output/folder` to save visual checks. Godot 4.7.2 on Apple M2 was used for the first verification.

## Four Rodin travelers

The Traveler dropdown now offers Willow Scout, Hearthland Ranger, Ridge Wayfarer, and Ember Forager. Each is a fixed modeled appearance with its own hair, clothing, and proportions. Name, background and keepsake remain independent cosmetic choices. Custom Scout (original) restores the original editable build, face, hair and palettes.

Press C in the clearing, choose a traveler, then Continue your journey to change appearance while retaining world progress and inventory. Existing profiles migrate to the original custom look; new profiles default to Willow Scout. Appearance format 2 records this selection separately from the world save. The source illustration is still the art target; these first skinned exports need further refinement.
