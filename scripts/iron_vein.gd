extends StaticBody3D
## A surface outcrop of iron ore. Strike it with a stone pickaxe; each hit frees one chunk of ore.
const MAX_HITS := 4
var ore_id := "iron_ore"
var hits_left := MAX_HITS
var art: Node3D
var collision: CollisionShape3D

func _ready() -> void:
	add_to_group("iron_veins" if ore_id == "iron_ore" else "copper_veins")
	art = Node3D.new()
	add_child(art)
	preload("res://scripts/imported_props.gd").rock(art, Vector3(1.7, 1.0, 1.4), ore_id)
	collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 1.0, 1.4)
	collision.shape = shape
	collision.position.y = 0.5
	add_child(collision)

func prompt() -> String:
	return "Stone pickaxe • Left click to mine %s (%d / %d)" % [ore_id.trim_suffix("_ore"), MAX_HITS - hits_left, MAX_HITS] if hits_left > 0 else "Worked-out %s vein" % ore_id.trim_suffix("_ore")

func mined_message() -> String:
	return "Vein worked out • E to gather the ore." if hits_left == 0 else "Copper ore chipped loose" if ore_id == "copper_ore" else "Iron ore chipped loose"

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
	pickup.item_id = ore_id
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
