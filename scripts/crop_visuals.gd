extends RefCounted
class_name CropVisuals

const CONTRACT_PATH := "res://assets/data/crop_sprite_contract.json"
const CELL_SIZE := 64
const STATES: Array[String] = ["seed_bag", "planted", "growing_1", "growing_2", "growing_3", "harvest_ready", "inventory", "rotten"]
const FIELD_STATES: Array[String] = ["planted", "growing_1", "growing_2", "growing_3", "harvest_ready"]
static var _entries: Dictionary = {}
static var _aliases: Dictionary = {}
static var _textures: Dictionary = {}

static func entries() -> Dictionary:
	if _entries.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
		if data is Dictionary:
			_entries = data.get("crops", {})
			_aliases = data.get("legacy_aliases", {})
	return _entries

static func visual_id_for(crop_id: String) -> String:
	entries()
	return String(_aliases.get(crop_id, crop_id))

static func has_complete_set(crop_id: String) -> bool:
	var entry: Dictionary = entries().get(visual_id_for(crop_id), {})
	if entry.is_empty() or not ResourceLoader.exists(String(entry.get("sheet", ""))): return false
	var frames: Dictionary = entry.get("frames", {})
	if frames.size() != STATES.size(): return false
	var indices: Array[int] = []
	for state: String in STATES:
		if not frames.has(state): return false
		var index: int = int(frames[state])
		if index < 0 or index >= STATES.size() or indices.has(index): return false
		indices.append(index)
	return true

static func texture(crop: Dictionary, state: String) -> Texture2D:
	var crop_id: String = String(crop.get("visual_id", crop.get("id", "")))
	if not STATES.has(state): return null
	var key := crop_id + ":" + state
	if _textures.has(key): return _textures[key]
	var entry: Dictionary = entries().get(crop_id, {})
	if entry.is_empty(): return null
	var index: int = int(entry.get("frames", {}).get(state, -1))
	if index < 0: return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(String(entry.sheet)) as Texture2D
	if atlas.atlas == null: return null
	atlas.region = Rect2(index * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
	_textures[key] = atlas
	return atlas

static func field_state(plot: Dictionary, crop: Dictionary, day_progress: float = 0.0) -> String:
	if bool(plot.get("wilted", false)): return "rotten"
	var growth: int = int(plot.get("growth", 0))
	var days: int = maxi(1, int(crop.get("days", 1)))
	if growth >= days: return "harvest_ready"
	if growth <= 0: return "planted"
	# Intermediate artwork can change during a watered day, including crops
	# with only three growing days. Harvest readiness still uses integer growth.
	var fraction: float = clampf(day_progress, 0.0, 0.99) if bool(plot.get("watered", false)) else 0.0
	var progress: float = (float(growth) + fraction) / float(days)
	if progress < 0.34: return "growing_1"
	if progress < 0.7: return "growing_2"
	return "growing_3"
