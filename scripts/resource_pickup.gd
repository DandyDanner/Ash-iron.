extends Area3D
const Model = preload("res://scripts/traveler_model.gd")
const Inventory = preload("res://scripts/inventory.gd")
@export var item_id := "stick"
@export var amount := 2
var collected := false

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
			Model.oval(self, Vector3(-0.1, 0.12, 0), Vector3(0.38, 0.26, 0.3), Color("a1a394"))
			Model.oval(self, Vector3(0.16, 0.085, 0.13), Vector3(0.24, 0.18, 0.23), Color("7e8b83"))
		"wood":
			for i in range(3):
				var log_mesh := Model.cylinder(self, Vector3((i - 1) * 0.17, 0.12, 0), 0.1, 0.6, Color("95633f"))
				log_mesh.rotation.x = PI / 2
		"stone_axe":
			var handle := Model.cylinder(self, Vector3(0, 0.08, 0), 0.026, 0.6, Color("86603c"))
			handle.rotation.x = PI / 2
			Model.oval(self, Vector3(0, 0.1, -0.22), Vector3(0.34, 0.16, 0.2), Color("89948c"))
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
			art.position.y = 0.11
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
			Model.box(self, Vector3(0, 0.16, 0), Vector3(0.60, 0.09, 0.34), Color("b18a57"))
			for x in [-0.20, 0.20]:
				Model.box(self, Vector3(x, 0.07, 0), Vector3(0.06, 0.14, 0.26), Color("795a3d"))
		"chest":
			Model.box(self, Vector3(0, 0.14, 0), Vector3(0.42, 0.24, 0.26), Color("8b6a44"))
			Model.box(self, Vector3(0, 0.27, 0), Vector3(0.44, 0.05, 0.28), Color("9a7750"))
			for x in [-0.14, 0.14]:
				Model.box(self, Vector3(x, 0.15, 0), Vector3(0.04, 0.28, 0.28), Color("4a4640"))

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
