extends Node3D
## One authored excursion on the existing outer terrain. No changes to starting resources.
const M = preload("res://scripts/traveler_model.gd")
const Terrain = preload("res://scripts/visual_clearing.gd")
const Pine = preload("res://scripts/harvest_tree.gd")
const Vein = preload("res://scripts/iron_vein.gd")
const ROUTE := [Vector2(12, -9), Vector2(25, -12), Vector2(34, -18), Vector2(42, -20), Vector2(53, -32)]

func _ready() -> void:
	for i in range(ROUTE.size() - 1):
		var a: Vector2 = ROUTE[i]
		var b: Vector2 = ROUTE[i + 1]
		var steps := ceili(a.distance_to(b) / 1.4)
		for j in range(steps):
			var p := a.lerp(b, float(j) / steps)
			# Small stone waymarks sit against the terrain; they are scenery, not loose resources.
			M.oval(self, Vector3(p.x, Terrain.terrain_height(p.x, p.y) + 0.02, p.y), Vector3(1.8, 0.07, 1.4), Color("626750"))
	_marker(Vector2(12, -9), "ECHO HOLLOW  →\nFollow the ochre markers")
	_marker(Vector2(29, -14), "ECHO HOLLOW\nSwelling throat? Back away or use rock cover.")
	_marker(Vector2(53, -32), "THE OLD LOOKOUT\nBring discoveries home. More paths to come.")
	for p in [Vector2(20,-12), Vector2(35,-18), Vector2(47,-25)]:
		_marker(p, "")
	# Hollow cover is permanent, even after harvesting the nearby pines.
	for p in [Vector2(38,-23), Vector2(46,-17)]:
		var rock := M.oval(self, Vector3(p.x, 1.85, p.y), Vector3(2.5, 1.8, 2.2), Color("737e68"))
		rock.create_convex_collision()
	for i in range(12):
		var angle := i * TAU / 12
		var p := Vector2(42 + sin(angle) * 11, -20 + cos(angle) * 11)
		if p.distance_to(Vector2(34,-18)) < 5 or p.distance_to(Vector2(49,-28)) < 5: continue
		var pine := Pine.new()
		pine.name = "EchoPine_%02d" % i
		pine.position = Vector3(p.x, Terrain.terrain_height(p.x,p.y), p.y)
		add_child(pine)
	var vein := Vein.new()
	vein.name = "EchoIronVein"
	vein.position = Vector3(54, Terrain.terrain_height(54,-29), -29)
	add_child(vein)
	# Low ruined lookout stones provide a recognizable destination, not a new building system.
	for i in range(6):
		var p := Vector2(50 + i * 1.15, -35)
		var stone := M.oval(self, Vector3(p.x, Terrain.terrain_height(p.x,p.y) + 0.5, p.y), Vector3(1.0, 1.0 + i % 2 * 0.3, 0.8), Color("90927e"))
		stone.create_convex_collision()

func _marker(p: Vector2, text: String) -> void:
	var foot := Vector3(p.x, Terrain.terrain_height(p.x, p.y), p.y) + Vector3(0, 0, 1.7)
	M.cylinder(self, foot + Vector3.UP * 0.65, 0.06, 1.3, Color("715538"))
	M.box(self, foot + Vector3.UP * 1.2, Vector3(0.5, 0.26, 0.045), Color("bd8d49"))
	if not text.is_empty():
		var label := Label3D.new()
		label.text = text
		label.position = foot + Vector3.UP * 1.9
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 25
		label.pixel_size = 0.006
		label.modulate = Color("f3dfb1")
		label.visibility_range_end = 15
		add_child(label)
