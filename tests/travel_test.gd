extends SceneTree

const Scene = preload("res://scenes/main.tscn")
const Places = preload("res://scripts/travel_world.gd")
const Saves = preload("res://scripts/save_manager.gd")
var failures: int = 0

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
	check(game.at_title and game.modal == "title", "startup must wait on title screen")
	var start_time: float = game.minute
	game._process(1.0)
	check(game.minute == start_time, "title must pause the clock")
	game._close_modal()
	check(game.modal == "title", "title cannot be dismissed into an unchosen game")
	game.at_title = false
	game._close_modal()
	game._sleep()
	check(game.modal == "confirm_sleep" and not game.sleeping, "sleep must ask for confirmation")
	game._cancel_confirmation()
	check(game.modal == "" and not game.sleeping and game.day == 1, "cancel sleep preserves day")
	game._sleep()
	game._begin_sleep()
	check(game.sleeping and game.day == 1, "confirmed sleep starts transition")
	game.sleeping = false
	var farm_props: Array = game._pack_state().props.duplicate(true)
	game._travel_to("river", false)
	check(game.location == "river" and game.energy == 95.0 and game.minute == start_time + 30, "walking costs energy and time")
	check(game.truck_location == "farm" and not game.truck_driving, "walking leaves truck behind")
	check(game._pack_state().props == farm_props, "visiting river preserves farm scenery")
	game.player_pos = Vector2(875,718)
	game.water = 0
	game._interact()
	check(game.water == game.max_water, "river interaction refills water")
	game._travel_to("town", true)
	check(game.location == "river", "remote truck cannot be summoned")
	game._travel_to("farm", false)
	game.player_pos = game.truck_pos + Vector2(-75,0)
	game.truck_cargo.append({"crop_id":"turnip", "count":5, "value":100})
	game._travel_to("town", true)
	check(game.location == "town" and game.truck_driving and game.truck_location == "town", "car moves player and truck to town")
	check(game.truck_cargo.size() == 1, "car preserves cargo")
	game._open_modal("travel")
	var back := InputEventJoypadButton.new()
	back.button_index = JOY_BUTTON_B
	back.pressed = true
	game._unhandled_input(back)
	check(game.modal == "", "controller B closes travel menu while driving")
	var packed: Dictionary = Saves.decode_game(Saves.encode_game(game._pack_state()))
	game._load_state(packed)
	check(game.location == "town" and game.truck_location == "town" and game.truck_driving, "save roundtrip preserves area and vehicle")
	game._interact()
	check(not game.truck_driving and not game._blocked(game.player_pos), "car exit places player in clear ground")
	game.player_pos = Vector2(560,580)
	game._interact()
	check(game.modal == "shop", "village store opens shop")
	game._close_modal()
	game.player_pos = game.truck_pos
	game.truck_driving = true
	game.player_pos = Vector2(560,580)
	game.truck_pos = game.player_pos
	var before: int = game.coins
	game._interact()
	check(game.truck_cargo.is_empty() and game.coins == before + 100, "village receives truck cargo")
	game._travel_to("river", false)
	check(game.truck_location == "town" and not game.truck_driving, "leaving car on foot parks it in source area")
	game.energy = 0
	game._travel_to("farm", false)
	check(game.location == "river", "exhausted player cannot walk between areas")
	check(Places.blocked("river",Vector2(1050,600)), "river water blocks passage")
	check(not Places.blocked("river",Vector2(1050,480)), "bridge allows river crossing")
	check(Places.blocked("town",Vector2(550,450)), "village buildings block passage")
	packed.erase("location")
	packed.erase("truck_location")
	game._load_state(packed)
	check(game.location == "farm" and game.truck_location == "farm", "old saves default to farm")
	game.free()
	_test_road_exits()
	if failures == 0: print("FARM LIFE travel: all checks passed")
	await process_frame
	await process_frame
	quit(1 if failures else 0)

func _test_road_exits() -> void:
	var game = Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	game.at_title = false
	game._close_modal()
	for x: int in range(54):
		for y: int in range(Places.ROAD_FIRST_ROW, Places.ROAD_LAST_ROW + 1):
			check(game._is_path(Vector2i(x,y)), "road spans the entire bottom of the farm")
	check(not game._is_path(Vector2i(32,20)), "former vertical road is gone")
	check(not game._is_path(Vector2i(30,29)), "former horizontal branch is gone")
	for prop: Dictionary in game.props:
		check(not game._prop_bounds(prop).intersects(Rect2(0,1088,1728,96)), "scenery leaves road clear")
	for area: String in ["farm","river","town"]:
		game.location = area
		for x: int in range(96,1633,32):
			check(not game._blocked(Vector2(x,Places.ROAD_Y)), "road is traversable across " + area)
	for driving: bool in [false,true]:
		game.location = "farm"
		game.truck_location = "farm"
		game.truck_driving = driving
		game.truck_cargo.assign([{"crop_id":"turnip","count":5,"value":100}])
		game.energy = 100.0
		game.minute = 360.0
		game.road_exit_cooldown = 0.0
		game.player_pos = Vector2(80,Places.ROAD_Y)
		if driving: game.truck_pos = game.player_pos
		Input.action_press("move_left")
		game._update_movement(0.05)
		Input.action_release("move_left")
		check(game.location == "river" and game.modal == "", "left movement automatically enters river without interaction")
		check(game.player_pos.x > 1400 and not game._blocked(game.player_pos), "river arrival is clear at right end")
		check(game.truck_driving == driving and game.truck_cargo.size() == 1, "travel preserves vehicle and cargo")
		check(game.energy == (100.0 if driving else 95.0), "automatic travel uses existing energy cost")
		check(game.minute == (370.0 if driving else 390.0), "automatic travel uses existing duration")
		game.road_exit_cooldown = 0.0
		check(not game._try_road_exit(Vector2.LEFT) and game.location == "river", "holding direction cannot bounce to previous map")
		game.player_pos = Vector2(1648,Places.ROAD_Y)
		if driving: game.truck_pos = game.player_pos
		check(game._try_road_exit(Vector2.RIGHT) and game.location == "farm", "right river exit returns to farm")
		game.road_exit_cooldown = 0.0
		game.player_pos = Vector2(1648,Places.ROAD_Y)
		if driving: game.truck_pos = game.player_pos
		check(game._try_road_exit(Vector2.RIGHT) and game.location == "town", "right farm exit enters town")
		check(game.player_pos.x < 400 and not game._blocked(game.player_pos), "town arrival is clear at left end")
		game.road_exit_cooldown = 0.0
		game.player_pos = Vector2(80,Places.ROAD_Y)
		if driving: game.truck_pos = game.player_pos
		check(game._try_road_exit(Vector2.LEFT) and game.location == "farm", "left town exit returns to farm")
	game.truck_driving = false
	game.road_exit_cooldown = 0.0
	game.player_pos = Vector2(80,800)
	check(not game._try_road_exit(Vector2.LEFT), "leaving map away from road cannot travel")
	game.player_pos = Vector2(80,Places.ROAD_Y)
	check(not game._try_road_exit(Vector2.ZERO), "standing near exit cannot trigger travel")
	game.moving_box_index = 0
	check(not game._try_road_exit(Vector2.LEFT), "carrying a crate prevents automatic travel")
	game.moving_box_index = -1
	game.road_exit_cooldown = 0.0
	game.energy = 0.0
	check(not game._try_road_exit(Vector2.LEFT), "automatic walking respects exhaustion")
	game.energy = 100.0
	game.minute = 1439.0
	game.road_exit_cooldown = 0.0
	check(not game._try_road_exit(Vector2.LEFT), "automatic travel respects end of day")
	game.minute = 360.0
	game.road_exit_cooldown = 0.0
	game._open_modal("pause")
	check(not game._try_road_exit(Vector2.LEFT), "paused game cannot trigger travel")
	game._close_modal()
	game.props.append({"tile":Vector2i(10,35),"kind":"tree","hp":3,"variant":2,"fruit_count":3,"fruit_days":0})
	game._load_state(Saves.decode_game(Saves.encode_game(game._pack_state())))
	for prop: Dictionary in game.props:
		check(not game._prop_bounds(prop).intersects(Rect2(0,1088,1728,96)), "loading older scenery clears the new road")
	game.free()
