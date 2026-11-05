extends SceneTree

const Scene = preload("res://scenes/main.tscn")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var game = Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	game.at_title = false
	game._close_modal()
	game.props.clear()
	# Scenery and unowned land must not capture the well interaction.
	for offset: Vector2 in [Vector2(0,40),Vector2(45,0),Vector2(0,-55),Vector2(-45,0)]:
		game.player_pos = Vector2(1008,592) + offset
		game.mouse_aim_active = true
		game.mouse_target_tile = Vector2i(31,18)
		game.water = 0
		game._interact()
		check(game.water == game.max_water and game.modal == "", "Well accessible from every side near unowned land")
		check(game.action_label.text.contains("Llenar regadera"), "Hint describes the action actually executed")
	game.player_pos = Vector2(1050,605)
	game.selected_tool = 1
	game.water = 0
	game._use_selected_tool()
	check(game.water == game.max_water, "Using watering can at well also refills")
	game.player_pos = Vector2(400,1000)
	game.mouse_target_tile = Vector2i(31,18)
	game.water = 0
	game._interact()
	check(game.water == 0 and game.modal == "", "Distant aim cannot refill or buy land")
	game.selected_tool = 0
	game._use_tool_at(Vector2i(18,18))
	check(not game.plots.has("18,18"), "Tools cannot affect distant tiles")
	game.player_pos = Vector2(592,624)
	game.props.append({"tile":Vector2i(18,18), "kind":"rock", "hp":3,"variant":0})
	game._hit_prop(Vector2i(18,18), "weed")
	check(not game.plots.has("18,18") and game.props.size() == 1, "Wrong tool cannot clear underneath a rock")
	game._use_tool_at(Vector2i(18,18))
	check(not game.plots.has("18,18"), "Cannot dig underneath objects")
	game.props.clear()
	game.props.append({"tile":Vector2i(18,18),"kind":"stump","hp":1,"variant":0})
	var wood: int = game.inventory.wood
	game._hit_prop(Vector2i(18,18),"tree")
	check(game.props.is_empty() and game.inventory.wood == wood + 2, "Chopped stump disappears and yields wood only once")
	game.plots["18,18"] = {"soil":"tilled","crop_id":"turnip","growth":0,"watered":false,"wilted":false,"dry_days":0}
	game.selected_tool = 1
	game.water = 5
	game._use_tool_at(Vector2i(18,18))
	var energy: float = game.energy
	game._use_tool_at(Vector2i(18,18))
	check(game.water == 4 and game.energy == energy, "Repeated watering wastes neither water nor energy")
	game.plots["18,18"].growth = 99
	game.plots["18,18"].watered = false
	game._use_tool_at(Vector2i(18,18))
	check(game.inventory.get("turnip", 0) == 0 and game.plots["18,18"].watered, "Watering mature plants does not accidentally harvest")
	game.player_pos = Vector2(100,100)
	game._harvest(Vector2i(18,18))
	check(game.inventory.get("turnip", 0) == 0, "Distant crops cannot be harvested")
	game.player_pos = Vector2(592,624)
	game._harvest(Vector2i(18,18))
	check(game.inventory.get("turnip",0) == 2, "Harvest enters the backpack immediately")
	game._sync_backpack()
	check(game.inventory_slots.has("turnip"), "Harvest has a backpack slot")
	game.plots.clear()
	# Charged tools still reach their 3x3 footprint.
	game.player_pos = Vector2(656,656)
	game.facing = Vector2.DOWN
	game.selected_tool = 0
	game.tool_levels.Azada = 2
	game.mouse_aim_active = false
	game.action_cooldown = 0.0
	game.tool_charge = 1.0
	game.energy = 100.0
	for y: int in range(20,23):
		for x: int in range(19,22):
			game.plots["%d,%d" % [x,y]] = {"soil":"cleared","crop_id":"","watered":false}
	game._use_selected_tool()
	for y: int in range(20,23):
		for x: int in range(19,22):
			check(game.plots["%d,%d" % [x,y]].soil == "tilled", "Charged hoe reaches full 3x3")
	game.selected_tool = 1
	# Destination water sources accept the tool as well as A/E.
	for area: String in ["town","river"]:
		game.action_cooldown = 0.0
		game.location = area
		game.player_pos = Vector2(896,676) if area == "town" else Vector2(875,718)
		game.water = 0
		game._use_selected_tool()
		check(game.water == game.max_water, "Water tool refills in " + area)
	game.location = "farm"
	game.truck_location = "farm"
	game.truck_pos = Vector2(700,600)
	game.player_pos = game.truck_pos
	game.truck_driving = true
	game.props.append({"tile":Vector2i(19,18),"kind":"rock","hp":3,"variant":0})
	game._interact()
	check(not game.truck_driving and not game._blocked(game.player_pos), "Truck exit finds clear ground")
	game.free()
	if failures == 0: print("FARM LIFE interactions: all checks passed")
	await process_frame
	await process_frame
	quit(1 if failures else 0)
