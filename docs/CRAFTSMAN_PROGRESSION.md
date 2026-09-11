# Craftsman progression

Dallon approved the material order on September 11, 2026:

**Stone → Copper → Bronze → Iron → Steel**

This is the target progression. The current build still requires a bench for stone tools and already prototypes iron mining/smelting. This document records the direction; it does not change live recipes, equipment or saves. The station layout and benefits below are the proposed implementation outline, with costs and balance still to be playtested.

## A new craft at each stage

| Stage | What the player learns | Proposed equipment and payoff |
| --- | --- | --- |
| Stone | Shape and lash gathered materials by hand, directly in the inventory | Stone axe, pickaxe and spear; enough to gather wood, defend yourself and begin mining without first needing a bench |
| Copper | Smelt the first metal in a primitive furnace and cast simple parts | A first copper tool and metal fittings for an improved crafting station; selective upgrades rather than replacing every stone item immediately |
| Bronze | Combine copper and tin, then cast better tools | More capable axes, picks and spearheads; tin gives expeditions a new discovery to bring home |
| Iron | Build an ironworking setup and learn forging | Versatile tools, weapons and useful structural parts; forging capability is the milestone, rather than making every bronze item instantly obsolete |
| Steel | Refine iron with carbon control and heat treatment | Premium edges and specialized equipment; efficient, reliable gear that rewards mastery |

These are game abstractions, not a historical chronology or a claim that every later material is better at every task. Introduce one useful item or technique at a time. Wood remains valuable for handles, structures, fuel and bindings alongside other gathered materials; a wooden chopping axe does not need its own equipment tier.

## Keep the journey interesting

- Better tools should change what you can do and how efficiently you do it. Damage alone should not define a tier. Durability and combat stamina remain future systems, not assumed current benefits.
- Let the player notice a resource before they can fully process it. Material knowledge and workshop capability can provide progression without requiring an enemy trophy for every metal.
- Make copper a satisfying, compact introduction. Avoid five complete equipment sets and five repetitions of the same mining chore. Keep useful older tools viable.
- Build the primitive furnace from resources obtainable with stone equipment. The first metalworking station must not require an item that only that station can make.
- Preserve convenient crafting from nearby chests. Tune costs to the eight-slot starting pack; the Explorer Pack should help exploration without becoming a hidden prerequisite for the first metal.
- Discoveries can later bring home techniques, workshop improvements or specialist opportunities. Villagers, relic bonuses and the Wayfarer's Lantern remain part of the broader design, outside this first crafting change.

## Next implementation slice

1. Move basic stone axe, pickaxe and spear recipes into inventory crafting. Show which recipes require a station and why. Keep placement, hotbar and connected-storage behavior coherent.
2. Add a compact copper loop: an accessible source, primitive smelting, one worthwhile copper item and fittings toward the improved station. Decide concrete recipes and timing as part of that implementation.
3. Verify a fresh player can complete the loop without recipe dependency traps. Verify full inventories, material transfers, furnace queues and save/reload.
4. Preserve existing iron ore, ingots, placed furnaces and progress during the transition. Explicitly migrate any changed save structure; do not silently rename or delete old items. Existing iron processing needs a compatibility decision before changing its availability.
5. Playtest stone/copper before adding tin/bronze, then iron forging and steel refinement. Do not expand the enemy roster or require a large new biome merely to supply the next material.
