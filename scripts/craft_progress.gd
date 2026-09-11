extends RefCounted
## Permanent learned techniques, earned only by successful crafting/placement/smelting.
const KEYS := ["stone_axe", "stone_pickaxe", "stone_spear", "bench_placed", "furnace_placed", "copper_smelted", "copperworking"]
var learned: Dictionary = {}

func earn(id: String) -> bool:
	if id not in KEYS or learned.get(id, false): return false
	learned[id] = true
	return true

func has(id: String) -> bool:
	return learned.get(id, false) == true

func lock_reason(id: String) -> String:
	match id:
		"bench":
			if not has("stone_axe"): return "Locked • Craft a stone axe in your backpack first."
		"furnace":
			if not has("stone_axe") or not has("stone_pickaxe"): return "Locked • Craft a stone axe and stone pickaxe first."
		"copper_fittings":
			if not has("furnace_placed"): return "Locked • Place a furnace first."
			if not has("copper_smelted"): return "Locked • Smelt your first copper ingot."
		"copperworking":
			if not has("copper_smelted"): return "Locked • Place a furnace and smelt copper first."
		"copper_axe":
			if not has("copperworking"): return "Locked • Fit the Copperworking kit at your bench."
	return ""

func next_step() -> String:
	if not has("stone_axe"): return "NEXT • Craft a stone axe by hand → unlock the workbench."
	if not has("bench_placed"): return "NEXT • Craft and place your workbench → bow, arrows, torch and chest."
	if not has("stone_pickaxe"): return "NEXT • Craft a stone pickaxe by hand → unlock the furnace recipe."
	if not has("furnace_placed"): return "NEXT • Craft a furnace at the bench, then place it."
	if not has("copper_smelted"): return "NEXT • Mine green-flecked outcrops → smelt Copper at your furnace."
	if not has("copperworking"): return "NEXT • Cast copper fittings → fit a Copperworking kit at the bench."
	return "COPPERWORKING LEARNED • Your benches can now make copper axes."

func to_data() -> Dictionary:
	return learned.duplicate()

func restore(raw: Variant, legacy: bool = false) -> void:
	learned.clear()
	if raw is Dictionary:
		for id in KEYS:
			if raw.get(id) is bool and raw[id]: learned[id] = true
	if legacy:
		# Before format 11 every stone/workshop recipe was available. Preserve that access.
		for id in ["stone_axe", "stone_pickaxe", "stone_spear"]: learned[id] = true
