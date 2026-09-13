extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Workbench = preload("res://scripts/workbench.gd")
const Furnace = preload("res://scripts/furnace.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("native_stations_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = Paths.path("native_stations_save_%d.json" % Time.get_ticks_usec())
	GameSave.clear()
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func mesh_triangles(node: Node) -> int:
	var total := 0
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			total += (indices.size() if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	return total

func has_native_pbr(node: Node) -> bool:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material != null and material.albedo_texture != null and material.normal_texture != null and material.roughness_texture != null:
				return true
	return false

func run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var bench := Workbench.new()
	host.add_child(bench)
	await process_frame
	var bench_native: Node3D = bench.find_child("NativeWorkbench", true, false)
	check(bench_native != null and mesh_triangles(bench_native) == 18000, "Workbench did not instantiate the 18k native mesh")
	check(has_native_pbr(bench_native), "Workbench lost native albedo, normal, or metallic-roughness data")
	var bench_box := bench.collision.shape as BoxShape3D
	check(bench_box != null and bench_box.size.is_equal_approx(Vector3(1.9, 1.05, 1.0)), "Native bench changed the placement/collision footprint")
	check(bench.find_child("CopperworkingKit", true, false) == null and not bench.copperworking, "Simple bench displays copper hardware before the upgrade")
	bench.show_copperworking()
	var kit: Node3D = bench.find_child("CopperworkingKit", true, false)
	check(bench.copperworking and kit != null and mesh_triangles(kit) > 0, "Copperworking kit is not a distinct visible upgrade")
	var kit_children := kit.get_child_count()
	bench.show_copperworking()
	check(kit.get_child_count() == kit_children, "Repeated copper unlock duplicated the visible kit")
	var near := Node3D.new()
	host.add_child(near)
	near.add_to_group("chests")
	near.position = Vector3(7.99, 0, 0)
	var far := Node3D.new()
	host.add_child(far)
	far.add_to_group("chests")
	far.position = Vector3(8.01, 0, 0)
	check(bench.linked_chests() == [near], "Native art changed the workbench connected-storage range")
	bench.position = Vector3(2, 0.2, 3)
	bench.rotation.y = 0.7
	var bench_data := bench.to_data()
	check(is_equal_approx(bench_data.x, 2.0) and is_equal_approx(bench_data.yaw, 0.7), "Native bench changed persisted placement data")

	var furnace := Furnace.new()
	host.add_child(furnace)
	furnace.set_process(false)
	await process_frame
	var furnace_native: Node3D = furnace.find_child("NativeFurnace", true, false)
	check(furnace_native != null and mesh_triangles(furnace_native) > 15000, "Furnace did not instantiate the cleaned native bloomery")
	check(has_native_pbr(furnace_native), "Furnace lost native albedo, normal, or metallic-roughness data")
	var furnace_collision := furnace.get_child(0) as CollisionShape3D
	var furnace_box := furnace_collision.shape as BoxShape3D
	check(furnace_box != null and furnace_box.size.is_equal_approx(Furnace.SIZE), "Native furnace changed the placement/collision footprint")
	check(furnace.embers.name == "EmberBed" and furnace.glow.name == "FurnaceGlow", "Furnace runtime fire nodes are missing")
	check(not furnace.glow.visible and not furnace.ember_material.emission_enabled, "Cold native furnace still appears lit")
	furnace.ore = Furnace.ORE_PER_INGOT
	furnace.fuel = Furnace.FUEL_PER_INGOT
	furnace._refresh_fire()
	check(furnace.is_burning() and furnace.glow.visible and furnace.ember_material.emission_enabled, "Smelting did not light the native furnace ember and glow")
	var saved := furnace.to_data()
	check(saved.ore == 2 and saved.fuel == 1 and saved.metal == "iron" and saved.auto_feed, "Native visuals changed furnace persistence data")
	GameSave.clear()
	print("NATIVE STATIONS: %s" % ("PASS — PBR assets, footprints, copper kit, storage range, persistence and cold/burning fire" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
