# Wilderness encounters and bringing discoveries home

September 11, 2026. Direction from Dallon's discussion; implemented details are separated from future concepts.

## Current playable slice

**Prepare at camp → follow the markers → learn Bellmaw's warning → bring its hide home → fit an Explorer Pack → carry more on the next excursion.**

The Bristleback remains the first animal. Bellmaw is the first strange creature: a broad, squat four-legged form with an expandable amber throat. A planted sonic attack, readable radius and rock cover distinguish its encounter from the boar's straight charge. Its warning is visible as well as audible. It needs no night cycle to test.

The current balance is 300 HP, 3.3 m/s approach, a 1.2-second warning, a 34-damage boom inside 7 m and a 1.25-second recovery. Thick hide halves damage outside recovery. Spear hits deal 20 during recovery and 10 while guarded; axe hits remain a weaker fallback at 10/5. The HUD identifies the soft-throat window. This needs playtesting for fairness, not just a longer health bar.

Both creatures return after 120 seconds of active play once their home is clear and the player is at least 8 m away. Menus and offline time do not count; remaining time is saved. Each defeat gives one hide.

Echo Hollow is an optional destination beyond the archery target. A short onward route reaches the Old Lookout and a fourth iron vein. The guaranteed hide reward buys a meaningful capacity increase instead of random loot or tiny stat increments. The route is open to exploration; killing Bellmaw is not an invisible gate.

The Explorer Pack increases eight slots to twelve for one Bellmaw hide, two wood and four sticks at a nearby workbench. It is fitted permanently, including with a full pack, and uses connected stock. Existing traveler models keep their backpack appearance. Armor and numerical character levels remain future decisions.

See [concept art](art/bellmaw-concept-v1.png) and [initial implementation review](art/ECHO_HOLLOW_REVIEW.md) and [latest actual refinement review](art/SURVIVAL_REFINEMENT_REVIEW.md). The model is a replaceable first gameplay sculpt, not an illustration-fidelity character asset.

The September 12 Rodin pass replaces Bellmaw and Bristleback visuals and provides animated Hollow Wolf/Meadow Buck preview assets. Wolf pack encounters and deer roaming/flee AI are still future work; the preview is a model/motion viewer. See [current creature review](art/CREATURE_RODIN_REVIEW.md).

## Keep these creature concepts

| Creature | Distinctive direction | Status |
| --- | --- | --- |
| Bellmaw | Low broad body; a swelling throat warns of a short-range boom; learn distance and cover. | First playable strange encounter. |
| Threadwing | A large flightless moth; folded fan wings resemble hanging bark/leaves; a sudden spread interrupts visibility. | Keep. Next candidate after testing Bellmaw; not implemented. |
| Night Harrow | An unnatural owl; recognizable perch/call, aerial approach, and useful overhead cover. | Later flying threat. |
| StoneWraith | Broad rock-armored burrower drawn to mining. Answering knocks and moving pebbles warn before it emerges. | Later mining encounter; avoid unwarned unavoidable hits. |
| Gloam Feeder | Large glowing wetland wanderer, feeding on remains and guarding feeding grounds. Observation and discovery can matter more than killing it. | Later landmark creature. |
| Hollow Wolf | Coordinated pack behavior and a recognizable warning; needs more identity than a reskinned wolf. | Native textured/rigged preview ready; pack AI and world placement later. |
| Unquiet | Sound-sensitive inhabitant of old places. Needs a distinct silhouette and fair sound cues. | Reconsider before building. |

Dallon rejected the Duskling's long-limbed, hooded forest-humanoid direction as too reminiscent of Valheim. Antlered wooden humanoids from the other sheets are also lower priority. Reference sheets express moods and possibilities, not a commitment to build every creature. Keep readable, stylized adventure forms; do not automatically carry over their heavier horror treatment.

## Future identity of Ash & Iron

- **Restore forgotten places:** discoveries can help restore a crossing, old workshop or landmark and make a new route useful.
- **Bring discoveries home:** relics should have a visible role. Candidate effects include garden yield, crafting/smelting speed or watering crops. Names/effects still need balancing.
- **A few memorable villagers:** specialists can interpret finds, help restore relics and give the home a reason to grow. Preserve the design brief's small cast rather than a settlement-management system.
- **Wayfarer's Lantern:** start with a small protected radius around a home/workbench. Material and discovery upgrades could expand it to gardens and later nearby homes. Give the boundary visible cues and have ordinary unwanted night attackers avoid it. Avoid turning protection into constant fuel upkeep. The precise enemy exceptions are undecided.

None of those four systems is implemented in the Bellmaw slice. Validate the prepare/explore/return/upgrade loop before adding them.
