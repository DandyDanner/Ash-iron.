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
