extends Area3D
const Model = preload("res://scripts/traveler_model.gd")
const Inventory = preload("res://scripts/inventory.gd")
@export var item_id := "stick"
@export var amount := 2
var collected := false
var fall_speed := 0.0
var settled := false

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 2
	collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.43
	collision.position.y = 0.12
	collision.shape = shape
	add_child(collision)
	match item_id:
		"bellmaw_hide":
			Model.oval(self, Vector3(0, 0.09, 0), Vector3(0.55, 0.17, 0.42), Color("be914f"))
			Model.box(self, Vector3(0, 0.16, 0), Vector3(0.05, 0.02, 0.44), Color("626d4c"))
		"boar_hide":
			Model.box(self, Vector3(0, 0.06, 0), Vector3(0.45, 0.08, 0.34), Color("805138"))
			Model.box(self, Vector3(0, 0.107, 0), Vector3(0.05, 0.015, 0.36), Color("c5af7f"))
		"stick":
			for i in range(2):
				var branch := Model.cylinder(self, Vector3((i - 0.5) * 0.15, 0.08, 0), 0.035, 0.68, Color("a07a4e"), 0.021)
				branch.rotation_degrees = Vector3(88, i * 35 - 15, 0)
			var fork := Model.cylinder(self, Vector3(0.12, 0.08, -0.15), 0.021, 0.27, Color("a07a4e"), 0.012)
			fork.rotation_degrees = Vector3(90, -45, 0)
		"stone":
			preload("res://scripts/imported_props.gd").rock(self, Vector3(.40, .23, .32), "stone")
		"wood":
			for i in range(3):
				var log_mesh := Model.cylinder(self, Vector3((i - 1) * 0.17, 0.12, 0), 0.1, 0.6, Color("95633f"))
				log_mesh.rotation.x = PI / 2
		"stone_axe", "copper_axe":
			var art := preload("res://scripts/native_equipment.gd").add(self, item_id)
			art.rotation.x = -PI / 2
			art.position = Vector3(0, 0.08, 0.13)
			art.scale = Vector3.ONE * .78
		"stone_pickaxe":
			var art := Node3D.new()
			add_child(art)
			preload("res://scripts/pickaxe_art.gd").build(art)
			art.rotation.x = -PI / 2
			art.position = Vector3(0, 0.065, 0.13)
			art.scale = Vector3.ONE * 0.75
		"torch":
			var handle := Model.cylinder(self, Vector3(0, 0.08, 0), 0.026, 0.6, Color("86603c"))
			handle.rotation.x = PI / 2
			Model.oval(self, Vector3(0, 0.1, -0.22), Vector3(0.13, 0.12, 0.20), Color("b88248"))
		"bow":
			var art := Node3D.new()
			add_child(art)
			preload("res://scripts/archery_art.gd").bow(art)
			art.rotation.x = PI / 2
			# Native recurves are deeper than the old procedural strip; raise the
			# laid-down bow so its grip and limbs rest on the terrain surface.
			art.position.y = 0.17
			art.scale = Vector3.ONE * 0.6
		"stone_spear":
			var art := Node3D.new()
			add_child(art)
			preload("res://scripts/spear_art.gd").build(art)
			art.position = Vector3(0, 0.06, 0.26)
			art.scale = Vector3.ONE * 0.70
		"arrow":
			var art := preload("res://scripts/archery_art.gd").arrow(self)
			art.position.y = 0.08
		"bench":
			var native: Node3D = preload("res://assets/props/workbench.glb").instantiate()
			native.name = "PackedNativeWorkbench"
			native.scale = Vector3.ONE * .60
			native.position.y = .02
			add_child(native)
		"iron_ore", "copper_ore":
			preload("res://scripts/imported_props.gd").rock(self, Vector3(.35, .25, .30), item_id)
		"iron_ingot", "copper_ingot", "copper_fittings":
			for i in range(2):
				Model.box(self, Vector3((i - 0.5) * 0.16, 0.05, 0), Vector3(0.12, 0.08, 0.34), (Color("c98752") if item_id.begins_with("copper") else Color("7f8a93")).lightened(i * 0.05))
		"furnace":
			var native: Node3D = preload("res://assets/props/furnace.glb").instantiate()
			native.name = "PackedNativeFurnace"
			native.scale = Vector3.ONE * .48
			native.position.y = .02
			add_child(native)
		"chest":
			var holder := Node3D.new()
			add_child(holder)
			preload("res://scripts/imported_props.gd").chest(holder)
			holder.scale = Vector3.ONE * .48

func prompt() -> String:
	return "E  •  Pick up %d %s" % [amount, Inventory.ITEMS[item_id].name.to_lower()]

func collect_into(inventory: RefCounted) -> int:
	if collected:
		return 0
	var received: int = inventory.add(item_id, amount)
	amount -= received
	if amount == 0:
		collected = true
		queue_free()
	return received

func _physics_process(delta: float) -> void:
	if collected or settled or not item_id in ["stone", "iron_ore", "copper_ore"]: return
	# Only terrain can support a mined fragment. Characters and furniture must not leave it floating.
	var ground := terrain_below(self, global_position)
	fall_speed += 9.8 * delta
	global_position.y -= fall_speed * delta
	if not ground.is_empty() and global_position.y <= ground.position.y + 0.025:
		global_position.y = ground.position.y + 0.025
		fall_speed = 0.0
		settled = true

static func terrain_below(node: Node3D, spot: Vector3) -> Dictionary:
	var excluded: Array[RID] = []
	for attempt in range(24):
		var query := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 3, spot + Vector3.DOWN * 40, 1, excluded)
		var hit := node.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider.is_in_group("placement_ground"): return hit
		excluded.append(hit.rid)
	return {}
