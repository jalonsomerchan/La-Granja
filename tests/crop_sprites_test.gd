extends SceneTree

const Visuals = preload("res://scripts/crop_visuals.gd")
const Crops = preload("res://scripts/crop_database.gd")
const Rules = preload("res://scripts/farming_rules.gd")
const Scene = preload("res://scenes/main.tscn")
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var entries: Dictionary = Visuals.entries()
	check(entries.size() >= 124, "All seasonal crops and wild fruits have complete sets")
	check(not Visuals.has_complete_set("new_fruit_without_art"), "A future variety without eight states is rejected")
	for crop_id: String in entries:
		check(Visuals.has_complete_set(crop_id), "Complete frame contract: " + crop_id)
		var crop := {"id":crop_id}
		var regions: Array[Rect2] = []
		for state: String in Visuals.STATES:
			var sprite := Visuals.texture(crop, state) as AtlasTexture
			check(sprite != null and sprite.atlas != null, crop_id + "/" + state + " loads in Godot")
			if sprite == null or sprite.atlas == null: continue
			check(sprite.get_size() == Vector2(64,64), "Consistent frame size")
			check(sprite.atlas.get_size() == Vector2(512,64), "Eight-frame atlas bounds")
			check(not regions.has(sprite.region), "Every role uses its own region")
			regions.append(sprite.region)
	for index: int in range(Crops.EXTENDED_NAMES.size()):
		var crop := Crops.by_id("catalog_%03d" % index)
		check(not crop.is_empty() and Visuals.has_complete_set(String(crop.get("id", ""))), "Legacy crops map to complete art: " + str(index))
	for fruit: Dictionary in Crops.WILD_FRUITS:
		check(Visuals.texture(Crops.by_id(fruit.id), "inventory") != null, "Wild fruit has a backpack sprite")
		check(Visuals.texture(Crops.by_id(fruit.id), "seed_bag") != null, "Wild fruit has a seed sprite")
	var crop: Dictionary = Crops.by_id("turnip")
	var plot := {"growth":0,"watered":false,"wilted":false}
	check(Visuals.field_state(plot,crop) == "planted", "New planting uses the planted sprite")
	plot.growth = 1
	check(Visuals.field_state(plot,crop) == "growing_1", "First growth has its own drawing")
	plot.growth = 2
	check(Visuals.field_state(plot,crop) == "growing_2", "Second growth has its own drawing")
	plot.watered = true
	check(Visuals.field_state(plot,crop,0.5) == "growing_3", "Even three-day crops can display the third growth drawing")
	check(not Rules.is_ready(plot,crop), "Visual growth cannot prematurely harvest crops")
	plot.growth = crop.days
	check(Visuals.field_state(plot,crop) == "harvest_ready", "Ripe crop uses harvest-ready art")
	plot.wilted = true
	check(Visuals.field_state(plot,crop) == "rotten", "Rotten sprite overrides maturity")
	# Missing and duplicate frame declarations cannot register a new crop.
	entries["incomplete_test"] = {"sheet":entries.turnip.sheet,"frames":{"seed_bag":0}}
	check(not Visuals.has_complete_set("incomplete_test"), "Incomplete state mapping is rejected")
	entries.erase("incomplete_test")
	var duplicate: Dictionary = entries.turnip.duplicate(true)
	duplicate.frames.rotten = duplicate.frames.inventory
	entries["duplicate_test"] = duplicate
	check(not Visuals.has_complete_set("duplicate_test"), "Reusing the same frame for different states is rejected")
	entries.erase("duplicate_test")
	var game = Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	for kind: String in ["seed", "product", "plant"]:
		var icon := game._crop_icon(crop,kind) as AtlasTexture
		var state: String = {"seed":"seed_bag","product":"inventory","plant":"harvest_ready"}[kind]
		check(icon == Visuals.texture(crop,state), "UI role consumes mandatory lifecycle art: " + kind)
	game.at_title = false
	game._close_modal()
	game.props.clear()
	game.player_pos = Vector2(656,688)
	game.plots.clear()
	for index: int in range(5):
		game.plots["%d,22" % (18+index)] = {"crop_id":"turnip","growth":index,"watered":true,"wilted":false,"soil":"tilled"}
	game.plots["23,22"] = {"crop_id":"turnip","growth":99,"watered":false,"wilted":true,"soil":"tilled"}
	game.queue_redraw()
	await process_frame
	await process_frame
	game.free()
	await process_frame
	print("Crop lifecycle sprites: %d failures" % failures)
	quit(1 if failures else 0)
