extends RefCounted
## Inventory and recipes share the same transactional slot rules.
## The backpack and storage chests are both instances of this class with different sizes.
## Recipes can draw from several inventories at once (backpack first, then connected chests);
## nothing is consumed unless the whole recipe, including its output, fits.
signal changed
const CAPACITY := 8
const EXPLORER_CAPACITY := 12
const CHEST_CAPACITY := 12
const ITEMS := {
	"bellmaw_hide": {"name": "Bellmaw hide", "stack": 10, "description": "Supple, strong hide from the Bellmaw at Echo Hollow. Bring it to a workbench for an Explorer Pack."},
	"explorer_pack": {"name": "Explorer Pack", "stack": 1, "description": "A permanent backpack upgrade from eight to twelve slots. Crafted and fitted at your workbench; uses no inventory slot."},
	"boar_hide": {"name": "Boar hide", "stack": 10, "description": "A hide from a Bristleback. Keep it for future leather equipment; no hide recipes yet."},
	"bench": {"name": "Simple workbench", "stack": 1, "description": "A portable crafting table. Select it and choose Place workbench here on clear, level ground. Craft tools nearby; pick it back up to move camp."},
	"stick": {"name": "Sticks", "stack": 10, "description": "Fallen branches. Gather by hand to make a bench and simple tools."},
	"stone": {"name": "Stones", "stack": 10, "description": "Loose stones from the clearing. No tool needed to pick them up."},
	"wood": {"name": "Wood", "stack": 10, "description": "Timber for chests, pine torches, or splitting into sticks at the bench."},
	"stone_axe": {"name": "Stone axe", "stack": 1, "description": "A shaped stone head on a wooden handle. Chop trees or swing at enemies for 10 damage (half a spear hit)."},
	"stone_pickaxe": {"name": "Stone pickaxe", "stack": 1, "description": "A pointed stone tool. Equip it and strike boulders to gather more stones."},
	"stone_spear": {"name": "Stone spear", "stack": 1, "description": "A stone-tipped hunting spear. Left click to thrust forward for 20 damage. Practice on the target at the far right of camp; does not chop or mine."},
	"torch": {"name": "Pine torch", "stack": 1, "description": "A warm pool of light for exploring. Equip from your hotbar; put away with the same key."},
	"bow": {"name": "Woodland bow", "stack": 1, "description": "A bent-wood bow. Hold left click to draw, release to shoot. Right click cancels the draw."},
	"arrow": {"name": "Arrows", "stack": 10, "description": "Stone-tipped ammunition. Each shot uses one arrow; recover landed arrows with E."},
	"chest": {"name": "Storage chest", "stack": 1, "description": "A banded wooden chest with twelve slots. Place it on solid ground near camp, then use it to keep supplies safe between trips. Chests near the bench feed its recipes."},
	"iron_ore": {"name": "Iron ore", "stack": 10, "description": "Rusty chunks chipped from an iron vein, or a lucky find inside a boulder. Smelt two with one wood in a furnace to make an ingot."},
	"iron_ingot": {"name": "Iron ingot", "stack": 10, "description": "Refined iron from the furnace. The first real metal; iron tools and weapons are the next milestone."},
	"furnace": {"name": "Stone furnace", "stack": 1, "description": "A squat stone furnace. Select it and choose Place furnace here on clear ground, then load iron ore and wood with E. It smelts on its own."}
}
const EQUIPPABLE := ["stone_axe", "stone_pickaxe", "torch", "bow", "stone_spear"]
const RECIPES := {
	"explorer_pack": {"name": "Explorer Pack", "cost": {"bellmaw_hide": 1, "wood": 2, "stick": 4}, "output": "explorer_pack", "amount": 1, "upgrade": true, "description": "Permanently adds four backpack slots (8 to 12). Find the Bellmaw beyond the archery target along the ochre trail markers. Crafted and fitted here; no empty slot needed."},
	"stone_spear": {"name": "Stone spear", "cost": {"wood": 2, "stone": 2}, "output": "stone_spear", "amount": 1, "description": "A melee weapon for short forward thrusts. Left click to strike the practice target within 2.8 meters. Does not harvest trees or rocks."},
	"bow": {"name": "Woodland bow", "cost": {"wood": 3, "stick": 2}, "output": "bow", "amount": 1, "description": "Hold left click to draw, release to fire. A longer draw shoots farther. Uses arrows from your backpack."},
	"arrows": {"name": "5 stone-tipped arrows", "cost": {"stick": 2, "stone": 1}, "output": "arrow", "amount": 5, "description": "Ammunition for your bow. Recover landed arrows with E. Arrows stack to ten."},
	"stone_pickaxe": {"name": "Stone pickaxe", "cost": {"stick": 3, "stone": 4}, "output": "stone_pickaxe", "amount": 1, "description": "Break boulders into loose stones. Four swings yield eight stones."},
	"torch": {"name": "Pine torch", "cost": {"stick": 2, "wood": 1}, "output": "torch", "amount": 1, "description": "A resinous pine torch. Hold it to light the ground ahead; no fuel upkeep yet."},
	"split_wood": {"name": "Split wood into sticks", "cost": {"wood": 1}, "output": "stick", "amount": 4, "description": "Turn one piece of timber into four crafting sticks."},
	"furnace": {"name": "Stone furnace", "cost": {"stone": 10, "wood": 2}, "output": "furnace", "amount": 1, "description": "A placeable furnace that turns two iron ore and one wood into an iron ingot every six seconds. Mine ore from the rusty veins at the clearing's edge."}
}
const BENCH_COST := {"stick": 6, "stone": 4}
const AXE_COST := {"stick": 3, "stone": 2}
const CHEST_COST := {"wood": 5, "stick": 2}
var slots: Array[Dictionary] = []

func _init(slot_count: int = CAPACITY) -> void:
	for i in range(maxi(1, slot_count)):
		slots.append({})

func count(item: String) -> int:
	var total := 0
	for slot in slots:
		if slot.get("item", "") == item:
			total += int(slot.amount)
	return total

func used_slots() -> int:
	var used := 0
	for slot in slots:
		if not slot.is_empty():
			used += 1
	return used

func is_empty() -> bool:
	return used_slots() == 0

func add(item: String, amount: int) -> int:
	if not ITEMS.has(item) or amount <= 0:
		return 0
	var received := _add_to(slots, item, amount)
	if received > 0:
		changed.emit()
	return received

static func _add_to(target: Array, item: String, amount: int) -> int:
	var remaining := amount
	var maximum: int = ITEMS[item].stack
	# Fill existing stacks before consuming an empty slot.
	for slot in target:
		if slot.get("item", "") == item:
			var added := mini(remaining, maximum - int(slot.amount))
			slot.amount += added
			remaining -= added
	for i in range(target.size()):
		if remaining == 0:
			break
		if target[i].is_empty():
			var added := mini(remaining, maximum)
			target[i] = {"item": item, "amount": added}
			remaining -= added
	return amount - remaining

static func _take_from(planned: Array, item: String, amount: int) -> int:
	var remaining := amount
	for i in range(planned.size()):
		if remaining == 0:
			break
		if planned[i].get("item", "") != item:
			continue
		var taken := mini(remaining, int(planned[i].amount))
		planned[i].amount -= taken
		remaining -= taken
		if planned[i].amount == 0:
			planned[i] = {}
	return amount - remaining

func can_afford(cost: Dictionary) -> bool:
	return can_afford_across([self], cost)

func can_craft(cost: Dictionary, output: String = "", amount: int = 1) -> bool:
	return can_craft_across([self], cost, output, amount)

func craft(cost: Dictionary, output: String = "", amount: int = 1) -> bool:
	return craft_across([self], cost, output, amount)

static func count_across(containers: Array, item: String) -> int:
	var total := 0
	for container in containers:
		total += container.count(item)
	return total

static func can_afford_across(containers: Array, cost: Dictionary) -> bool:
	for item in cost:
		if count_across(containers, item) < int(cost[item]):
			return false
	return true

static func can_craft_across(containers: Array, cost: Dictionary, output: String = "", amount: int = 1) -> bool:
	return not _plan_across(containers, cost, output, amount).is_empty()

static func craft_across(containers: Array, cost: Dictionary, output: String = "", amount: int = 1) -> bool:
	## Spends the recipe across the given inventories in order and puts the output in the first one.
	var plans := _plan_across(containers, cost, output, amount)
	if plans.is_empty():
		return false
	for i in range(containers.size()):
		if containers[i].slots != plans[i]:
			containers[i].slots.assign(plans[i])
			containers[i].changed.emit()
	return true

static func _plan_across(containers: Array, cost: Dictionary, output: String, amount: int) -> Array:
	if containers.is_empty() or not can_afford_across(containers, cost) or amount < 1 or (not output.is_empty() and not ITEMS.has(output)):
		return []
	var plans := []
	for container in containers:
		plans.append(container.slots.duplicate(true))
	for item in cost:
		if not ITEMS.has(item) or int(cost[item]) < 0:
			return []
		var remaining: int = cost[item]
		for planned in plans:
			remaining -= _take_from(planned, item, remaining)
			if remaining == 0:
				break
		if remaining > 0:
			return []
	if not output.is_empty() and _add_to(plans[0], output, amount) != amount:
		return []
	return plans

func take_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return {}
	var taken := slots[index].duplicate()
	slots[index] = {}
	changed.emit()
	return taken

func move_slot(index: int, target: RefCounted) -> int:
	## Moves as much of one stack as fits into another inventory; the remainder stays put.
	if index < 0 or index >= slots.size() or slots[index].is_empty() or target == self:
		return 0
	var item: String = slots[index].item
	var moved: int = target.add(item, int(slots[index].amount))
	if moved <= 0:
		return 0
	if moved >= int(slots[index].amount):
		slots[index] = {}
	else:
		slots[index].amount -= moved
	changed.emit()
	return moved

func to_data() -> Array:
	var data := []
	for slot in slots:
		data.append(slot.duplicate())
	return data

static func clean_slots(raw: Variant, slot_count: int) -> Array[Dictionary]:
	## Rebuilds a slot list from untrusted save data; unknown items or bad counts become empty slots.
	var result: Array[Dictionary] = []
	for i in range(slot_count):
		result.append({})
	if not (raw is Array):
		return result
	for i in range(mini(slot_count, raw.size())):
		var entry: Variant = raw[i]
		if not (entry is Dictionary) or entry.is_empty():
			continue
		var item: Variant = entry.get("item", "")
		var amount: Variant = entry.get("amount", 0)
		if not (item is String) or not ITEMS.has(item) or not (amount is int or amount is float):
			continue
		var kept := clampi(int(amount), 0, int(ITEMS[item].stack))
		if kept > 0:
			result[i] = {"item": item, "amount": kept}
	return result

func restore(raw: Variant) -> void:
	slots.assign(clean_slots(raw, slots.size()))
	changed.emit()

func expand_backpack() -> void:
	while slots.size() < EXPLORER_CAPACITY:
		slots.append({})
	changed.emit()
