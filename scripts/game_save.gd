extends RefCounted
## World progress: player, backpack, clearing resources, workbenches, chests, veins, and furnaces.
## Character appearance lives in character_profile.gd; the two files never overwrite each other.

const SAVE_PATH := "user://save.json"
const VERSION := 9
static var storage_path: String = SAVE_PATH

static func exists(path: String = "") -> bool:
	return FileAccess.file_exists(path if not path.is_empty() else storage_path)

static func load_state(path: String = "") -> Dictionary:
	if path.is_empty():
		path = storage_path
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not (parser.data is Dictionary):
		return {}
	var data: Dictionary = parser.data
	if not int(data.get("version", 0)) in range(1, VERSION + 1):
		return {}
	# Older saves keep all progress; the world supplies defaults for missing equipment, rocks, or airborne arrows.
	return data

static func save_state(data: Dictionary, path: String = "") -> Error:
	if path.is_empty():
		path = storage_path
	data = data.duplicate(true)
	data["version"] = VERSION
	data["saved_at"] = Time.get_unix_time_from_system()
	# Write then rename so an interrupted save never truncates the previous progress.
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	return DirAccess.rename_absolute(path + ".tmp", path)

static func clear(path: String = "") -> void:
	if path.is_empty():
		path = storage_path
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
