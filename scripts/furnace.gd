extends StaticBody3D
## A placeable stone furnace. Load iron ore and wood; it smelts on its own while you work elsewhere.
const Model = preload("res://scripts/traveler_model.gd")
const ORE_PER_INGOT := 2
const FUEL_PER_INGOT := 1
const SMELT_TIME := 6.0
const CAPACITY := 10
const SIZE := Vector3(1.0, 1.3, 1.0)
var ore := 0
var fuel := 0
var ingots := 0
var progress := 0.0
var burning_time := 0.0
var glow: OmniLight3D
var embers: MeshInstance3D
var ember_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("furnaces")
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = SIZE
	collision.shape = shape
	collision.position.y = SIZE.y * 0.5
	add_child(collision)
	var stone := Color("6d6f68")
	var mortar := Color("4d4b45")
	# Stacked stone courses on a slab, a lintel over the mouth, a cap, and a chimney at the back.
	Model.box(self, Vector3(0, 0.08, 0), Vector3(1.0, 0.16, 1.0), mortar)
	for course in range(3):
		var y := 0.27 + course * 0.22
		for side in [-1.0, 1.0]:
			Model.box(self, Vector3(side * 0.34, y, 0.0), Vector3(0.30, 0.20, 0.96), stone.lightened(course * 0.04))
		Model.box(self, Vector3(0, y, -0.34), Vector3(0.40, 0.20, 0.28), stone.darkened(0.05))
		if course > 0:
			Model.box(self, Vector3(0, y, 0.30), Vector3(0.40, 0.20, 0.34), stone.lightened(0.02))
	Model.box(self, Vector3(0, 0.88, 0), Vector3(0.98, 0.10, 0.98), mortar)
	Model.box(self, Vector3(0, 1.10, -0.25), Vector3(0.36, 0.40, 0.36), stone.darkened(0.08))
	Model.box(self, Vector3(0, 1.31, -0.25), Vector3(0.42, 0.04, 0.42), mortar)
	# The mouth: a dark cavity with embers that glow while smelting.
	Model.box(self, Vector3(0, 0.27, 0.30), Vector3(0.38, 0.20, 0.36), Color("1e1a17"))
	embers = Model.oval(self, Vector3(0, 0.21, 0.36), Vector3(0.30, 0.10, 0.20), Color("3a2a22"))
	ember_material = embers.material_override
	glow = OmniLight3D.new()
	glow.position = Vector3(0, 0.35, 0.6)
	glow.light_color = Color("ff9a3c")
	glow.light_energy = 1.4
	glow.omni_range = 4.0
	glow.visible = false
	add_child(glow)
	_refresh_fire()

func is_burning() -> bool:
	return ore >= ORE_PER_INGOT and fuel >= FUEL_PER_INGOT and ingots < CAPACITY

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	## Smelting is driven by time; partial progress waits for more ore or fuel rather than resetting.
	if not is_burning():
		_refresh_fire()
		return
	progress += delta / SMELT_TIME
	burning_time += delta
	var finished := 0
	while progress >= 1.0 and is_burning():
		progress -= 1.0
		ore -= ORE_PER_INGOT
		fuel -= FUEL_PER_INGOT
		ingots += 1
		finished += 1
	if not is_burning():
		progress = 0.0
	if finished > 0:
		_notify()
	_refresh_fire()

func _refresh_fire() -> void:
	var burning := is_burning()
	glow.visible = burning
	glow.light_energy = 1.2 + sin(burning_time * 9.0) * 0.25
	ember_material.emission_enabled = burning
	ember_material.emission = Color("ff7a2a")
	ember_material.emission_energy_multiplier = 2.2
	ember_material.albedo_color = Color("d0602a") if burning else Color("3a2a22")

func _notify() -> void:
	var world := get_parent()
	if world and world.has_method("mark_dirty"):
		world.mark_dirty()

func prompt() -> String:
	if is_burning():
		return "E  •  Use furnace   (smelting: %d ore, %d wood, %d ingot%s ready)" % [ore, fuel, ingots, "" if ingots == 1 else "s"]
	if ingots > 0:
		return "E  •  Use furnace   (%d ingot%s ready)" % [ingots, "" if ingots == 1 else "s"]
	return "E  •  Use furnace   (cold: needs iron ore and wood)"

func load_item(inventory: RefCounted, item: String, wanted: int = CAPACITY) -> int:
	## Moves ore or wood from an inventory into the furnace and returns how many were moved.
	if not item in ["iron_ore", "wood"]:
		return 0
	var room := CAPACITY - (ore if item == "iron_ore" else fuel)
	var amount := mini(mini(room, inventory.count(item)), wanted)
	if amount <= 0 or not inventory.craft({item: amount}):
		return 0
	if item == "iron_ore":
		ore += amount
	else:
		fuel += amount
	_notify()
	_refresh_fire()
	return amount

func take_ingots(inventory: RefCounted) -> int:
	var received: int = inventory.add("iron_ingot", ingots)
	ingots -= received
	if received > 0:
		_notify()
		_refresh_fire()
	return received

func is_empty() -> bool:
	return ore == 0 and fuel == 0 and ingots == 0

func to_data() -> Dictionary:
	return {"x": global_position.x, "y": global_position.y, "z": global_position.z, "yaw": rotation.y, "ore": ore, "fuel": fuel, "ingots": ingots, "progress": progress}

func restore(data: Dictionary) -> void:
	ore = clampi(int(_num(data.get("ore"))), 0, CAPACITY)
	fuel = clampi(int(_num(data.get("fuel"))), 0, CAPACITY)
	ingots = clampi(int(_num(data.get("ingots"))), 0, CAPACITY)
	progress = clampf(_num(data.get("progress")), 0.0, 0.999)
	_refresh_fire()

static func _num(value: Variant) -> float:
	return float(value) if (value is float or value is int) else 0.0
