extends SceneTree

const Crops = preload("res://scripts/crop_database.gd")
const Rules = preload("res://scripts/farming_rules.gd")
const Main = preload("res://scenes/main.tscn")
var failures: int = 0

func check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = Main.instantiate()
	root.add_child(game)
	game.set("at_title", false)
	game.call("_close_modal")
	game.set("coins", 100000)
	check(Crops.all_crops().size() == 120, "Exactly 120 crops")
	var ids: Dictionary = {}
	for season: String in ["Primavera", "Verano", "Otoño", "Invierno"]:
		check(Crops.crops_for_season(season).size() == 30, "30 crops in " + season)
	for crop: Dictionary in Crops.all_crops():
		check(not ids.has(crop.id), "Unique id: " + crop.id)
		ids[crop.id] = true
		check(crop.days > 0 and crop.days < 28 and crop.seed > 0 and crop.sell > 0, "Valid economy and growth")
		check(Rules.can_plant("tilled", crop, crop.season, false), "Plant in assigned season")
		check(not Rules.can_plant("tilled", crop, "invalid", false), "Reject wrong season")
		var plot: Dictionary = {"growth":0,"watered":true,"wilted":false,"dry_days":0}
		for day: int in range(crop.days):
			plot.watered = true
			plot = Rules.daily_growth(plot, false)
		var harvest: Dictionary = Rules.harvest(plot, crop)
		check(harvest.yield == crop.yield, "Harvest yield for " + crop.id)
		if crop.repeat > 0:
			check(not Rules.is_ready(harvest.plot, crop), "No immediate repeat harvest")
			for day: int in range(crop.repeat):
				harvest.plot.watered = true
				harvest.plot = Rules.daily_growth(harvest.plot, false)
			check(Rules.is_ready(harvest.plot, crop), "Regrowth matches declared interval")
		else:
			check(harvest.plot.is_empty(), "Single crops clear plot")
		for kind: String in ["product", "plant", "seed"]:
			var icon: AtlasTexture = game.call("_crop_icon", crop, kind)
			check(icon != null and icon.atlas != null and icon.get_size() == Vector2(64,64), "Valid sprite " + crop.id + " " + kind)
			check(icon.region.end.x <= icon.atlas.get_width() and icon.region.end.y <= icon.atlas.get_height(), "Sprite region contained")
		var before: int = int(game.get("inventory").get(crop.id + "_seed", 0))
		var coins: int = game.get("coins")
		game.call("_buy_seed", crop.id)
		check(game.get("coins") == coins - crop.seed, "Bag price matches purchase")
		check(game.get("inventory")[crop.id + "_seed"] == before + 5, "Bag contains 5 seeds")
		game.call("_select_seed", crop.id)
		check(game.get("selected_seed_id") == crop.id, "All crops selectable")
		game.set("season_index", ["Primavera", "Verano", "Otoño", "Invierno"].find(crop.season))
		game.set("player_pos", Vector2(592,624))
		game.set("energy", 100.0)
		game.set("carried_crop_count", 0)
		var plots: Dictionary = game.get("plots")
		plots["18,18"] = {"soil":"tilled","crop_id":"","growth":0,"watered":false,"dry_days":0,"wilted":false}
		game.call("_use_tool_at", Vector2i(18,18))
		check(plots["18,18"].crop_id == crop.id, "Game plants " + crop.id)
		check(game.get("inventory")[crop.id + "_seed"] == before + 4, "Planting consumes one seed")
		plots["18,18"].growth = crop.days
		game.call("_harvest", Vector2i(18,18))
		check(game.get("inventory").get(crop.id, 0) == 2 and game.get("carried_crop_count") == 0, "Game harvests " + crop.id)
	game.set("carried_crop_count", 0)
	game.set("selected_seed_id", "turnip")
	var visited: Dictionary = {}
	for season: int in range(4):
		game.set("season_index", season)
		for index: int in range(30):
			game.call("_cycle_seed", 1)
			visited[game.get("selected_seed_id")] = true
	check(visited.size() == 120, "Seed cycling reaches every crop")
	for season: int in range(4):
		game.call("_choose_shop_season", season)
		check(game.get("modal") == "shop", "Seasonal shop opens")
	game.call("_open_modal", "inventory")
	game.call("_open_modal", "seeds")
	game.call("_close_modal")
	var state: Dictionary = game.call("_pack_state")
	game.call("_load_state", state)
	check(game.get("inventory").has("perifollo_seed"), "New seeds survive save/load")
	game.free()
	await process_frame
	print("Seasonal crops: %d failures" % failures)
	quit(1 if failures else 0)
