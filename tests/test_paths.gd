extends RefCounted
## Test data stays in the OS temporary folder, separate from all real game saves.
static func path(filename: String) -> String:
	var directory := OS.get_environment("TMPDIR")
	if directory.is_empty():
		directory = OS.get_environment("TEMP")
	if directory.is_empty():
		directory = "/tmp"
	directory = directory.path_join("ash-iron-tests")
	DirAccess.make_dir_recursive_absolute(directory)
	return directory.path_join(filename)

static func place_bench(world: Node3D, spot: Vector3 = Vector3(-3.5, 0.2, 0.3)) -> Node3D:
	## Fixture for tests of systems that already require an established workshop.
	var bench := preload("res://scripts/workbench.gd").new()
	world.add_child(bench)
	bench.global_position = spot
	return bench

static func craft_and_place_bench(player: Node3D) -> bool:
	player.global_position = Vector3(-3.5, 1.1, 2.5)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	if not player.craft_bench().begins_with("Workbench crafted"):
		return false
	for i in range(player.inventory.slots.size()):
		if player.inventory.slots[i].get("item", "") == "bench":
			return player.place_workbench(i).begins_with("Workbench placed")
	return false
