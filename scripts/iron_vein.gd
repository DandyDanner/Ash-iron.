extends StaticBody3D
## A surface outcrop of iron ore. Strike it with a stone pickaxe; each hit frees one chunk of ore.
const Model = preload("res://scripts/traveler_model.gd")
const MAX_HITS := 4
var hits_left := MAX_HITS
var art: Node3D
var collision: CollisionShape3D

func _ready() -> void:
	add_to_group("iron_veins")
	art = Node3D.new()
	add_child(art)
	var rock := Color("6a4f42")
	var rust := Color("c8602a")
	Model.oval(art, Vector3(0, 0.45, 0), Vector3(1.7, 1.0, 1.4), rock)
	Model.oval(art, Vector3(0.5, 0.35, 0.3), Vector3(1.0, 0.7, 0.9), rock.lightened(0.06))
	Model.oval(art, Vector3(-0.45, 0.3, -0.35), Vector3(0.9, 0.65, 0.8), rock.darkened(0.08))
	# Ore shows as bright rusty nodules and streaks breaking through the surface all around the outcrop.
	for i in range(10):
		var a := i * 0.63
		var reach := Vector3(0.80, 0.0, 0.66)
		var spot := Vector3(sin(a) * reach.x, 0.30 + (i % 3) * 0.15, cos(a) * reach.z)
		var nodule := Model.box(art, spot, Vector3(0.24, 0.16, 0.20), rust.lightened((i % 3) * 0.08))
		nodule.rotation = Vector3(sin(a) * 0.6, a * 0.7, cos(a) * 0.5)
	for i in range(3):
		var streak := Model.box(art, Vector3(-0.3 + i * 0.3, 0.86 - i * 0.05, -0.2 + i * 0.25), Vector3(0.7, 0.05, 0.10), rust)
		streak.rotation = Vector3(0, 0.5 + i * 0.7, -0.15)
	collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 1.0, 1.4)
	collision.shape = shape
	collision.position.y = 0.5
	add_child(collision)

func prompt() -> String:
	return "Stone pickaxe • Left click to mine iron (%d / %d)" % [MAX_HITS - hits_left, MAX_HITS] if hits_left > 0 else "Worked-out iron vein"

func mined_message() -> String:
	return "Vein worked out • E to gather the ore." if hits_left == 0 else "Iron ore chipped loose"

func mine(hit_position: Vector3) -> bool:
	if hits_left <= 0:
		return false
	hits_left -= 1
	# Each strike frees one chunk of ore on the player's side of the outcrop.
	var outward := hit_position - global_position
	outward.y = 0
	outward = outward.normalized() if outward.length_squared() > 0.001 else Vector3.FORWARD
	var spot := global_position + outward * 1.35 + Vector3(cos(hits_left * 2.1), 0, sin(hits_left * 2.1)) * 0.3
	var pickup := preload("res://scripts/resource_pickup.gd").new()
	pickup.item_id = "iron_ore"
	pickup.amount = 1
	get_parent().add_child(pickup)
	pickup.global_position = spot + Vector3.UP * 0.3
	pickup.fall_speed = -1.2
	pickup.rotation.y = hits_left * 1.3
	restore(hits_left)
	return true

func restore(hits: int) -> void:
	hits_left = clampi(hits, 0, MAX_HITS)
	# The outcrop flattens as it is worked and stops blocking anything once it is gone.
	art.scale = Vector3(1.0, 0.3 + 0.7 * float(hits_left) / MAX_HITS, 1.0)
	collision.set_deferred("scale", art.scale)
	collision.set_deferred("disabled", hits_left == 0)
