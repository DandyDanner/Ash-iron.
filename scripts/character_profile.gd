extends RefCounted
## Cosmetic choices only. Backgrounds never change movement, combat, or resources.

const SAVE_PATH := "user://character.json"
static var storage_path: String = SAVE_PATH
const BACKGROUNDS := ["Trapper", "Apprentice", "Wanderer", "Prospector"]
const STORIES := [
	"You know the quiet language of the woods. Now you're looking for a place to call your own.",
	"You've spent years making things for others. Out here, you can build something of your own.",
	"There is always another bend in the trail. This time, you might find a reason to stay.",
	"An old map brought you to the mountains. The promise of a new life will keep you here."
]
const KEEPSAKES := ["Carved fox", "Worn compass", "Family scarf", "Old journal"]
const MEMORIES := [
	"A little wooden fox, polished by years in your pocket. Someone made it just for you.",
	"The brass is scratched, but the needle still points north. It has brought you home before.",
	"Mended more than once. Still warm. Still carrying a little of the home you left behind.",
	"Half-filled pages, pressed leaves, and plenty of room for whatever comes next."
]
const SKINS := [Color("f2ceaa"), Color("dfae87"), Color("bf875f"), Color("986449"), Color("724932"), Color("493027")]
const HAIR_COLORS := [Color("392b27"), Color("765035"), Color("c8a161"), Color("a95333"), Color("ddd5ba"), Color("20252b")]
const CLOTHES := [Color("617e65"), Color("527785"), Color("ab6546"), Color("aa8b51"), Color("786c88"), Color("58636a")]
const HAIR_STYLES := ["Tousled", "Cropped", "Long", "Topknot", "Braids", "Shaved"]
const BUILDS := ["Lean", "Balanced", "Broad"]
const FACES := ["Soft", "Angular", "Round"]

static func defaults() -> Dictionary:
	return {"version": 1, "name": "", "background": 2, "keepsake": 0, "skin": 1, "hair_color": 0, "hair": 0, "build": 1, "face": 0, "clothes": 0}

static func clean(raw: Dictionary) -> Dictionary:
	var result := defaults()
	var limits := {"background": 4, "keepsake": 4, "skin": 6, "hair_color": 6, "hair": 6, "build": 3, "face": 3, "clothes": 6}
	for key in limits:
		var value: Variant = raw.get(key, result[key])
		if value is int or value is float:
			result[key] = clampi(int(value), 0, limits[key] - 1)
	var raw_name: Variant = raw.get("name", "")
	if raw_name is String:
		result.name = raw_name.replace("\n", " ").replace("\r", " ").replace("\t", " ").strip_edges().left(24)
	return result

static func load_profile(path: String = "") -> Dictionary:
	if path.is_empty():
		path = storage_path
	if not FileAccess.file_exists(path):
		return defaults()
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return defaults()
	return clean(parser.data) if parser.data is Dictionary else defaults()

static func save_profile(profile: Dictionary, path: String = "") -> Error:
	if path.is_empty():
		path = storage_path
	# Write then rename so an interrupted save does not truncate the previous character.
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(clean(profile), "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	return DirAccess.rename_absolute(path + ".tmp", path)
