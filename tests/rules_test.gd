extends SceneTree

const CropDB = preload("res://scripts/crop_database.gd")
const Farm = preload("res://scripts/farming_rules.gd")
const Fruit = preload("res://scripts/fruit_rules.gd")
const Economy = preload("res://scripts/economy_rules.gd")
const Saves = preload("res://scripts/save_manager.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const OakSprite: Texture2D = preload("res://assets/sprites/trees/oak.png")
const AppleSprite: Texture2D = preload("res://assets/sprites/trees/apple.png")
const PropsAtlas: Texture2D = preload("res://assets/sprites/props/ground_props_atlas.png")
const CropsAtlas: Texture2D = preload("res://assets/sprites/crops/crop_atlas.png")
const TerrainAtlas: Texture2D = preload("res://assets/sprites/terrain/terrain_atlas.png")
const PlayerActions: Texture2D = preload("res://assets/sprites/animations/player_tool_actions.png")

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_crop_catalog()
	_test_planting_and_growth()
	_test_harvest_regrowth()
	_test_economy()
	_test_save_roundtrip()
	_test_sprite_atlases()
	_test_object_spacing()
	_test_wild_fruit()
	_test_gamepad_detection_and_rest()
	if failures == 0: print("FARM LIFE rules: all checks passed")
	else: push_error("FARM LIFE rules: %d check(s) failed" % failures)
	await process_frame
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)

func _test_crop_catalog() -> void:
	var crops: Array[Dictionary] = CropDB.all_crops()
	_check(crops.size() == 120, "catalog needs exactly 120 seasonal crops")
	var ids: Dictionary = {}
	for crop: Dictionary in crops:
		_check(not ids.has(crop.id), "crop ids must be unique")
		ids[crop.id] = true
	_check(CropDB.by_id("tomato").days == 6, "tomato data should be available")
	_check(CropDB.by_id("catalog_080").size() > 0, "extended catalog should be searchable")

func _test_planting_and_growth() -> void:
	var carrot: Dictionary = CropDB.by_id("carrot")
	_check(Farm.can_plant("tilled", carrot, "Primavera", false))
	_check(not Farm.can_plant("tilled", carrot, "Invierno", false))
	_check(not Farm.can_plant("grass", carrot, "Primavera", false))
	var plot := {"growth": 2, "watered": true, "dry_days": 0}
	var grown: Dictionary = Farm.daily_growth(plot, false)
	_check(grown.growth == 3 and grown.dry_days == 0, "watered plots grow")
	var rain_plot: Dictionary = Farm.daily_growth({"growth":1,"watered":false,"dry_days":0}, true)
	_check(rain_plot.growth == 2, "rain waters outdoor crops")
	var dry_plot := {"growth":0,"watered":false,"dry_days":2}
	_check(Farm.daily_growth(dry_plot, false).wilted, "three dry days wilt crops")

func _test_harvest_regrowth() -> void:
	var tomato: Dictionary = CropDB.by_id("tomato")
	var ripe := {"growth":6,"watered":false,"wilted":false}
	_check(Farm.is_ready(ripe, tomato))
	var harvest: Dictionary = Farm.harvest(ripe, tomato)
	_check(harvest.yield == 2 and harvest.plot.growth == 4, "repeat crop should regrow")
	var single: Dictionary = Farm.harvest({"growth":3,"wilted":false}, CropDB.by_id("carrot"))
	_check(single.yield == 0, "immature crop should not harvest")
	var ripe_carrot := {"growth":4,"wilted":false}
	_check(Farm.harvest(ripe_carrot, CropDB.by_id("carrot")).plot.is_empty(), "single harvest clears crop")

func _test_economy() -> void:
	var buy: Dictionary = Economy.buy(180, 32, 2)
	_check(buy.ok and buy.balance == 116 and buy.quantity == 2)
	_check(not Economy.buy(20, 32).ok, "insufficient funds should reject purchase")
	var sale: Dictionary = Economy.sell(100, 34, 8, 3)
	_check(sale.quantity == 3 and sale.balance == 202, "selling clamps to stock")
	var upgrade: Dictionary = Economy.upgrade(1, 100, 3, 2)
	_check(upgrade.ok and upgrade.level == 2 and upgrade.balance == 20)
	_check(not Economy.upgrade(6, 500, 9, 9).ok, "maximum tool cannot be upgraded")

func _test_save_roundtrip() -> void:
	var expected := {"day":7,"coins":321,"plots":{"18,20":{"crop_id":"tomato","growth":4}}}
	var loaded: Dictionary = Saves.decode_game(Saves.encode_game(expected))
	_check(loaded.get("day") == 7 and loaded.get("coins") == 321, "save JSON should preserve top-level state")
	_check(loaded.plots["18,20"].crop_id == "tomato", "save JSON should preserve plot state")
	var test_path: String = "/private/tmp/farm_life_save_test.json"
	_check(Saves.save_game_at(expected, test_path), "atomic disk save should write")
	var disk_state: Dictionary = Saves.load_game_from(test_path)
	_check(disk_state.get("day") == 7 and disk_state.plots["18,20"].crop_id == "tomato", "atomic disk save should round-trip")
	for suffix: String in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(test_path + suffix): DirAccess.remove_absolute(test_path + suffix)

func _test_gamepad_detection_and_rest() -> void:
	var main: Node = MainScene.instantiate()
	root.add_child(main)
	main.set("at_title", false)
	main.call("_close_modal")
	main.set("player_pos", Vector2(592,624))
	main.call("_hit_prop",Vector2i(18,18),"weed")
	var plots: Dictionary = main.get("plots")
	_check(plots.has("18,18") and plots["18,18"].soil == "cleared", "scythe should reveal the cleared-soil state")
	main.set("selected_tool",0)
	main.call("_use_tool_at",Vector2i(18,18))
	plots = main.get("plots")
	_check(plots["18,18"].soil == "tilled", "hoe should turn cleared soil into furrows")
	main.set("player_pos", Vector2(704,560))
	var initial_day: int = int(main.get("day"))
	main.call("_interact")
	_check(main.get("modal") == "confirm_sleep" and not bool(main.get("sleeping")) and int(main.get("day")) == initial_day, "interacting by the house asks before ending the day")
	main.call("_begin_sleep")
	_check(bool(main.get("sleeping")) and int(main.get("day")) == initial_day, "confirming sleep starts the transition without advancing the day yet")
	main.set("sleeping", false)
	var pad_event := InputEventJoypadButton.new()
	main.call("_unhandled_input", pad_event)
	_check(bool(main.get("last_input_was_gamepad")), "gamepad input should select gamepad hints")
	var key_event := InputEventKey.new()
	main.call("_unhandled_input", key_event)
	_check(not bool(main.get("last_input_was_gamepad")), "keyboard input should switch the hints back")
	if main.get("sfx_player") != null: main.get("sfx_player").stop()
	main.free()

func _test_sprite_atlases() -> void:
	_check(OakSprite.get_size() == Vector2(80,96), "oak sprite should use its 80x96 source frame")
	_check(AppleSprite.get_size() == Vector2(80,96), "apple tree sprite should match the oak frame")
	_check(PropsAtlas.get_size() == Vector2(192,192), "ground prop atlas should contain nine 64px cells")
	_check(CropsAtlas.get_size() == Vector2(256,256), "crop atlas should contain sixteen 64px cells")
	_check(TerrainAtlas.get_size() == Vector2(64,64), "terrain atlas should contain four 32px states")
	_check(PlayerActions.get_size() == Vector2(128,288), "player action atlas should contain six rows of four 32x48 frames")

func _test_object_spacing() -> void:
	var main: Node = MainScene.instantiate()
	root.add_child(main)
	main.set("at_title", false)
	main.call("_make_world")
	_check_layout(main)
	var scenery: Array[Dictionary] = main.get("props")
	_check(scenery.size() > 70, "spaced world still contains ample resources")
	var tree := {"tile":Vector2i(22,21),"kind":"tree","variant":2,"hp":2,"fruit_count":3,"fruit_days":0}
	scenery.append(tree)
	scenery.append({"tile":Vector2i(22,21),"kind":"bush","variant":0,"hp":1,"fruit_count":0,"fruit_days":3})
	scenery.append({"tile":Vector2i(21,14),"kind":"rock","variant":1,"hp":2})
	var before := scenery.size()
	var packed: Dictionary = main.call("_pack_state")
	main.call("_load_state", Saves.decode_game(Saves.encode_game(packed)))
	_check(main.get("props").size() == before, "repair relocates conflicting resources instead of deleting them")
	_check_layout(main)
	var found := false
	for prop: Dictionary in main.get("props"):
		if prop.kind == "tree" and prop.hp == 2:
			found = prop.fruit_count == 3 and prop.fruit_days == 0
	_check(found, "relocation preserves fruit and damage state")
	var first: Dictionary = main.call("_pack_state")
	main.call("_load_state", Saves.decode_game(Saves.encode_game(first)))
	_check(main.call("_pack_state").props == first.props, "loading a repaired layout does not move objects again")
	main.call("_close_modal")
	main.set("coins",1000)
	main.call("_buy_land")
	_check_layout(main)
	if main.get("sfx_player") != null: main.get("sfx_player").stop()
	main.free()

func _check_layout(main: Node) -> void:
	var scenery: Array[Dictionary] = main.get("props")
	var obstacles: Array[Rect2] = main.call("_layout_obstacles")
	for i: int in range(scenery.size()):
		var bounds: Rect2 = main.call("_prop_bounds",scenery[i])
		for obstacle: Rect2 in obstacles:
			_check(not bounds.intersects(obstacle), "scenery stays clear of paths, buildings, water, fences ")
		for j: int in range(i):
			_check(not bounds.intersects(main.call("_prop_bounds",scenery[j])), "neighboring sprites do not overlap")

func _test_wild_fruit() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 72
	var intervals: Dictionary = {}
	for sample: int in range(40):
		var prop := {"kind":"tree", "variant":2}
		Fruit.reset(prop, rng)
		intervals[prop.fruit_days] = true
		var wait: int = int(prop.fruit_days)
		_check(wait >= 3 and wait <= 5, "apple cadence stays within 3–5 days")
		for elapsed: int in range(wait - 1):
			Fruit.advance_day(prop, rng)
			_check(prop.fruit_count == 0, "fruit cannot ripen early")
		Fruit.advance_day(prop, rng)
		_check(prop.fruit_count in [2,3] and prop.fruit_days == 0, "fruit ripens on scheduled day")
		var count: int = int(prop.fruit_count)
		Fruit.advance_day(prop, rng)
		_check(prop.fruit_count == count, "unpicked fruit remains without accumulating")
	_check(intervals.size() > 1, "plants should have varied random intervals")
	for sample: Dictionary in [{"kind":"tree","variant":1}, {"kind":"bush","variant":0}, {"kind":"bush","variant":1}, {"kind":"bush","variant":2}]:
		Fruit.initialize(sample, rng)
		var config: Dictionary = Fruit.SPECIES[Fruit.species(sample)]
		_check(not CropDB.by_id(String(config.product)).is_empty(), "all fruit products can be priced and stored")
		Fruit.reset(sample, rng)
		_check(sample.fruit_days >= config.min_days and sample.fruit_days <= config.max_days, "each species uses its own interval")
	var oak := {"kind":"tree", "variant":0}
	Fruit.advance_day(oak, rng)
	_check(not oak.has("fruit_count"), "decorative oaks do not produce fruit")
	var main: Node = MainScene.instantiate()
	root.add_child(main)
	var apple := {"tile":Vector2i(17,23), "kind":"tree", "variant":2, "hp":3, "fruit_count":3, "fruit_days":0}
	var world_props: Array[Dictionary] = main.get("props")
	world_props.clear()
	world_props.append(apple)
	main.set("player_pos", Vector2(560,784))
	main.set("energy", 50.0)
	_check(main.call("_harvest", Vector2i(17,23)), "ripe trees support the common harvest entry point")
	_check(main.get("inventory").get("apple", 0) == 3, "tree fruit accumulates in backpack")
	_check(main.get("props").size() == 1 and apple.hp == 3 and apple.fruit_count == 0, "picking fruit keeps the plant and removes visible fruit")
	var wait: int = int(apple.fruit_days)
	main.call("_harvest", Vector2i(17,23))
	_check(main.get("inventory").get("apple", 0) == 3 and apple.fruit_days == wait, "repeat interaction cannot duplicate fruit or reroll the timer")
	main.set("player_pos", Vector2(912,560))
	var state: Dictionary = Saves.decode_game(Saves.encode_game(main.call("_pack_state")))
	main.call("_load_state", state)
	_check(main.get("props")[0].fruit_days == wait and main.get("props")[0].fruit_count == 0, "save/load preserves harvested state and countdown")
	main.set("day",28)
	main.call("_advance_day")
	_check(main.get("props")[0].fruit_days == wait - 1, "fruit timers survive month transitions")
	var loaded_apple: Dictionary = main.get("props")[0]
	loaded_apple.fruit_count = 2
	loaded_apple.fruit_days = 0
	var loaded_tile: Vector2i = loaded_apple.tile
	main.set("player_pos", Vector2(loaded_tile * 32) + Vector2(16,48))
	main.call("_harvest", loaded_tile)
	_check(main.get("inventory").get("apple",0) == 5, "successive wild harvests accumulate in the backpack")
	var coins_before: int = int(main.get("coins"))
	main.set("at_title",false)
	main.call("_close_modal")
	main.call("_sell_crop","apple")
	_check(main.get("coins") == coins_before+190 and main.get("inventory").get("apple",0) == 0, "five normal apples sell directly from the backpack")
	main.call("_close_modal")
	var bush := {"tile":Vector2i(17,23), "kind":"bush", "variant":1, "hp":1, "fruit_count":2, "fruit_days":0}
	world_props = main.get("props")
	world_props.clear()
	world_props.append(bush)
	main.set("player_pos", Vector2(100,100))
	main.call("_harvest",Vector2i(17,23))
	_check(bush.fruit_count == 2 and main.get("inventory").get("blueberry",0) == 0, "distant plants cannot be harvested")
	main.set("player_pos", Vector2(560,784))
	main.call("_harvest", Vector2i(17,23))
	_check(main.get("inventory").get("blueberry", 0) == 2 and bush.fruit_count == 0 and main.get("props").size() == 1, "bushes regrow instead of being destroyed by picking")
	bush.fruit_count = 3
	bush.fruit_days = 0
	main.call("_harvest", Vector2i(17,23))
	_check(bush.fruit_count == 0 and main.get("inventory").get("blueberry", 0) == 5, "successive harvests stack in the backpack")
	main.call("_hit_prop", Vector2i(17,23), "weed")
	_check(main.get("props").is_empty(), "scythe can still deliberately clear a bush")
	if main.get("sfx_player") != null: main.get("sfx_player").stop()
	main.free()

func _check(condition: bool, message: String = "check failed") -> void:
	if not condition:
		failures += 1
		push_error(message)
