extends RefCounted
class_name SaveManager

const SAVE_PATH := "user://farm_life_save.json"
const TEMP_PATH := "user://farm_life_save.tmp"
const BACKUP_PATH := "user://farm_life_save.bak"
const VERSION := 1

static func save_game(data: Dictionary) -> bool:
	var user_dir: String = ProjectSettings.globalize_path("user://")
	if not DirAccess.dir_exists_absolute(user_dir) and DirAccess.make_dir_recursive_absolute(user_dir) != OK:
		return false
	return _write_atomic(data, ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(BACKUP_PATH))

static func save_game_at(data: Dictionary, save_abs: String) -> bool:
	var parent: String = save_abs.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent) and DirAccess.make_dir_recursive_absolute(parent) != OK:
		return false
	return _write_atomic(data, save_abs, save_abs + ".tmp", save_abs + ".bak")

static func _write_atomic(data: Dictionary, save_abs: String, temp_abs: String, backup_abs: String) -> bool:
	var file: FileAccess = FileAccess.open(temp_abs, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encode_game(data))
	file.flush()
	file.close()
	if FileAccess.file_exists(backup_abs): DirAccess.remove_absolute(backup_abs)
	var had_previous: bool = FileAccess.file_exists(save_abs)
	if had_previous and DirAccess.rename_absolute(save_abs, backup_abs) != OK:
		return false
	if DirAccess.rename_absolute(temp_abs, save_abs) != OK:
		if had_previous: DirAccess.rename_absolute(backup_abs, save_abs)
		return false
	if had_previous: DirAccess.remove_absolute(backup_abs)
	return true

static func load_game() -> Dictionary:
	var path: String = SAVE_PATH if FileAccess.file_exists(SAVE_PATH) else BACKUP_PATH
	if not FileAccess.file_exists(path):
		return {}
	return load_game_from(ProjectSettings.globalize_path(path))

static func load_game_from(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var content: String = file.get_as_text()
	file.close()
	return decode_game(content)

static func encode_game(data: Dictionary) -> String:
	return JSON.stringify({"version": VERSION, "game": data})

static func decode_game(content: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(content)
	if not parsed is Dictionary or int(parsed.get("version", 0)) != VERSION:
		return {}
	return parsed.get("game", {})
