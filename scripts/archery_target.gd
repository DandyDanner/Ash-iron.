extends StaticBody3D
const Model = preload("res://scripts/traveler_model.gd")
var hits := 0
var last_result := ""
var sign: Label3D

func _ready() -> void:
	add_to_group("archery_targets")
	for x in [-0.5, 0.5]:
		Model.cylinder(self, Vector3(x, 0.85, 0), 0.065, 1.7, Color("846044"))
	for i in range(4):
		var radii := [0.9, 0.68, 0.43, 0.17]
		var colors := [Color("c5af79"), Color("e8dec0"), Color("496f65"), Color("c16d46")]
		var disc := Model.cylinder(self, Vector3(0, 1.4, 0.02 * i), radii[i], 0.1, colors[i])
		disc.rotation.x = PI / 2
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.9
	shape.height = 0.18
	collider.shape = shape
	collider.position.y = 1.4
	collider.rotation.x = PI / 2
	add_child(collider)
	sign = Label3D.new()
	sign.position = Vector3(0, 2.6, 0)
	sign.text = "WEAPON PRACTICE\nBow: hold / release • Spear / axe: click"
	sign.font_size = 38
	sign.pixel_size = 0.009
	sign.outline_size = 8
	add_child(sign)

func hit_by_arrow(point: Vector3) -> String:
	hits += 1
	var local := to_local(point) - Vector3(0, 1.4, 0)
	var distance := Vector2(local.x, local.y).length()
	last_result = "Bullseye!" if distance <= 0.18 else ("Inner ring!" if distance <= 0.45 else "Target hit!")
	sign.text = "%s\n%d hit%s • E to recover arrows" % [last_result, hits, "" if hits == 1 else "s"]
	return last_result + " • Recover your arrow with E."

func prompt() -> String:
	return "Practice target • Bow: hold / release • Spear / axe: click to strike"

func receive_melee_hit(_damage: int, point: Vector3) -> String:
	hits += 1
	var local := to_local(point) - Vector3(0, 1.4, 0)
	last_result = "Melee bullseye!" if Vector2(local.x, local.y).length() <= 0.18 else "Melee hit!"
	sign.text = "%s\n%d practice hit%s" % [last_result, hits, "" if hits == 1 else "s"]
	return last_result
