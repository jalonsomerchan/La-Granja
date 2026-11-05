extends SceneTree

const Scene = preload("res://scenes/main.tscn")
const Crops = preload("res://scripts/crop_database.gd")
const Saves = preload("res://scripts/save_manager.gd")
var failures: int = 0
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _pad(button: JoyButton, pressed: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event

func _tap(button: JoyButton) -> void:
	Input.parse_input_event(_pad(button))
	await process_frame
	Input.parse_input_event(_pad(button, false))
	await process_frame

func _buttons(node: Node) -> Array[Button]:
	var found: Array[Button] = []
	if node is Button: found.append(node)
	for child: Node in node.get_children(): found.append_array(_buttons(child))
	return found

func _reset_work() -> void:
	game.at_title = false
	game._close_modal()
	game.props.clear()
	game.plots.clear()
	game.player_pos = Vector2(592, 624)
	game.facing = Vector2.UP
	game.mouse_aim_active = false
	game.aim_stick = Vector2.ZERO
	game.energy = 100.0
	game.action_cooldown = 0.0
	game.assisted_actions = true
	game.inventory = {"turnip_seed": 10}
	game.quality_stock = {}
	game.selected_seed_id = "turnip"
	game.season_index = 0

func _run() -> void:
	game = Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	# These are Godot 4 SDL button indices, including the actual shoulders.
	for mapping: Array in [["tool_prev", JOY_BUTTON_LEFT_SHOULDER], ["tool_next", JOY_BUTTON_RIGHT_SHOULDER], ["pause_game", JOY_BUTTON_START], ["interact", JOY_BUTTON_A], ["use_tool", JOY_BUTTON_X], ["ui_cancel", JOY_BUTTON_B]]:
		check(_pad(mapping[1]).is_action_pressed(mapping[0]), "Correct controller mapping: " + mapping[0])
	_reset_work()
	var tile := Vector2i(18,18)
	# One deliberate press per stage; a held A cannot silently seed or water.
	game._input(_pad(JOY_BUTTON_A))
	check(game.plots["18,18"].soil == "cleared", "A clears the target without changing tools manually")
	game.action_cooldown = 0.0
	game._primary_action(true)
	check(game.plots["18,18"].soil == "cleared", "Held A cannot advance the same tile to a different task")
	game._input(_pad(JOY_BUTTON_A))
	check(game.plots["18,18"].soil == "tilled", "Second press prepares soil")
	game.action_cooldown = 0.0
	game._input(_pad(JOY_BUTTON_A))
	check(game.plots["18,18"].crop_id == "turnip" and game.inventory.turnip_seed == 9, "Third press plants selected seeds")
	game.action_cooldown = 0.0
	game._input(_pad(JOY_BUTTON_A))
	check(game.plots["18,18"].watered and game.water == 11, "Fourth press waters the plant")
	var energy: float = game.energy
	game.action_cooldown = 0.0
	game._primary_action(true)
	check(game.energy == energy and game.water == 11, "Holding on a watered plant spends nothing")
	game.plots["18,18"].growth = 99
	game.selected_tool = 3
	game._input(_pad(JOY_BUTTON_X))
	check(game.inventory.get("turnip", 0) == 0 and game.plots["18,18"].crop_id == "turnip", "Explicit tool never harvests by accident")
	game.action_cooldown = 0.0
	game._input(_pad(JOY_BUTTON_A))
	check(game.inventory.get("turnip", 0) == 2 and game.carried_crop_count == 0, "A harvests into backpack")
	game.plots["18,18"] = {"crop_id":"carrot", "growth":99,"soil":"tilled","watered":true,"wilted":false}
	game.action_cooldown = 0.0
	game._input(_pad(JOY_BUTTON_A))
	check(game.inventory.get("carrot", 0) == 2 and game.inventory.turnip == 2, "Different crops accumulate without a trip to a crate")
	# Moving reorients a previously aimed target.
	game.aim_stick = Vector2.LEFT
	Input.action_press("move_right")
	game._update_movement(0.0)
	Input.action_release("move_right")
	check(game._target_tile().x == 19, "Movement clears stale right-stick aim")
	# Continuous analog trigger events must not reset the charge timer.
	game.selected_tool = 0
	game.tool_levels.Azada = 2
	game.action_cooldown = 0.0
	game.facing = Vector2.DOWN
	for y: int in range(19,22):
		for x: int in range(17,20): game.plots["%d,%d" % [x,y]] = {"soil":"cleared","crop_id":""}
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	game._input(trigger)
	game.tool_charge = 0.8
	trigger.axis_value = 0.95
	game._input(trigger)
	check(game.tool_charge == 0.8, "Analog jitter does not restart charging")
	trigger.axis_value = 0.0
	game._input(trigger)
	check(game.tool_charge == 0.0 and not game.charge_armed, "Releasing trigger consumes charge")
	for y: int in range(19,22):
		for x: int in range(17,20): check(game.plots["%d,%d" % [x,y]].soil == "tilled", "Charged action covers 3x3")
	# Pausing cancels pending charges and held actions.
	game._input(_pad(JOY_BUTTON_START))
	check(game.modal == "pause" and not game.charge_armed, "Start pauses and cancels tool charge")
	var minute: float = game.minute
	game._process(2.0)
	check(game.minute == minute, "Menus stop the day clock")
	game._input(_pad(JOY_BUTTON_B))
	check(game.modal == "", "B resumes from pause")
	game._on_joy_connection_changed(0, false)
	check(game.modal == "pause", "Controller disconnection pauses gameplay")
	game._close_modal()
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.modal == "pause", "Focus loss pauses gameplay")
	game._close_modal()
	# Quiet stick noise cannot switch input device.
	game.last_input_was_gamepad = false
	trigger.axis = JOY_AXIS_LEFT_X
	trigger.axis_value = 0.05
	game._input(trigger)
	check(not game.last_input_was_gamepad, "Stick drift does not steal keyboard hints")
	# Cargo uses all known produce IDs, including wild fruit absent from seed catalog.
	game.player_pos = game.truck_pos + Vector2(-80,0)
	game.inventory = {"apple":10}
	game.quality_stock = {"apple":{"normal":6,"excelente":4}}
	for index: int in range(game.produce_boxes.size()): game.produce_boxes[index] = {"crop_id":"","count":0}
	game.produce_boxes[0] = {"crop_id":"apple","count":3}
	game.produce_box_tiles[0] = Vector2i(34,19)
	game.truck_cargo.clear()
	game._quick_load_truck()
	check(game.truck_cargo.size() == 3 and game.inventory.apple == 0, "Quick loading combines a partial crate with loose produce exactly once")
	check(game._cargo_value() == 471, "Loading preserves the full quality-adjusted crop value")
	game._quick_load_truck()
	check(game.truck_cargo.size() == 3, "Repeated load cannot duplicate stock")
	var coins: int = game.coins
	game._sell_truck_cargo()
	check(game.coins == coins + 471 and game.truck_cargo.is_empty(), "Selling consumes cargo and pays its value")
	game.inventory = {"apple":40}
	game.quality_stock = {"apple":{"normal":40}}
	game._quick_load_truck()
	check(game.truck_cargo.size() == 6 and game.inventory.apple == 10, "Truck capacity leaves excess produce safe in backpack")
	# Direct sale keeps physical crates reserved.
	game.truck_cargo.clear()
	game.produce_boxes[0] = {"crop_id":"apple","count":3}
	game._sell_all_produce()
	check(game.inventory.apple == 3 and game.produce_boxes[0].count == 3, "Shop sale cannot also sell reserved crate contents")
	game._close_modal()
	# Legacy fruit in hands migrates once, preserving quality.
	var state: Dictionary = Saves.decode_game(Saves.encode_game(game._pack_state()))
	state.carried_crop_id = "pear"
	state.carried_crop_count = 3
	state.carried_quality = "buena"
	state.assisted_actions = false
	state.relaxed_clock = false
	game._load_state(state)
	check(game.inventory.pear == 3 and game.quality_stock.pear.buena == 3 and game.carried_crop_count == 0, "Old hand cargo migrates into backpack once")
	check(not game.assisted_actions and not game.relaxed_clock, "Playability preferences survive save/load")
	# Every seasonal shop page is reachable; purchase preserves focus.
	game.coins = 100000
	for season: int in range(4):
		game._choose_shop_season(season)
		for page: int in range(6):
			game.shop_page = page
			game._open_modal("shop")
			var buys: int = 0
			for button: Button in _buttons(game.modal_body):
				if button.text.begins_with("Comprar "): buys += 1
			check(buys == 5, "Five readable crops per page in every season")
	game._choose_shop_season(0)
	for button: Button in _buttons(game.modal_body):
		if button.text.begins_with("Comprar Zanahoria"):
			button.grab_focus()
			break
	game._buy_seed("carrot")
	var focused: Control = root.gui_get_focus_owner()
	check(focused is Button and focused.text.begins_with("Comprar Zanahoria"), "Purchase keeps focus on the same crop")
	game._show_settings()
	var settings_buttons := _buttons(game.modal_body)
	settings_buttons[2].grab_focus()
	game._toggle_setting("relaxed_clock")
	focused = root.gui_get_focus_owner()
	check(focused is Button and focused.text.begins_with("Ritmo del día"), "Toggling a setting keeps focus in place")
	game.confirmation_back = "pause"
	game._open_modal("confirm_new")
	focused = root.gui_get_focus_owner()
	check(focused is Button and focused.text.begins_with("Cancelar"), "Destructive confirmations default to cancel")
	game._input(_pad(JOY_BUTTON_B))
	check(game.modal == "pause", "B returns from confirmation to its parent")
	await process_frame
	await process_frame
	# Exercise the actual Godot GUI event path as well as direct action dispatch.
	await _tap(JOY_BUTTON_DPAD_DOWN)
	focused = root.gui_get_focus_owner()
	check(focused is Button and focused.text == "Mochila", "D-pad navigates real focused GUI buttons")
	await _tap(JOY_BUTTON_A)
	check(game.modal == "inventory", "A activates the focused GUI button without triggering farm actions")
	await _tap(JOY_BUTTON_B)
	check(game.modal == "pause", "B returns from inventory to its opening pause menu")
	await _tap(JOY_BUTTON_B)
	check(game.modal == "", "B closes pause after returning from its child")
	game._open_modal("pause")
	await process_frame
	await process_frame
	check(Rect2(Vector2.ZERO, Vector2(1280,800)).encloses(game.modal_panel.get_global_rect()), "Modal stays within Steam Deck screen")
	game._close_modal()
	game.plots.clear()
	game.plots["18,18"] = {"crop_id":"turnip","growth":0,"soil":"tilled","watered":false,"wilted":false,"dry_days":0}
	game.season_index = 0
	game.day = 1
	game.rain_today = true
	game._advance_day()
	check(game.plots["18,18"].growth == 1, "Overnight growth uses the rain of the day just completed")
	check(game.plots["18,18"].watered == game.rain_today, "New day's rainfall is visible on the crops")
	var snapshot: Dictionary = game._pack_state()
	var previous_stock: int = int(snapshot.inventory.get("apple", 0))
	game.inventory.apple = 999
	check(int(snapshot.inventory.get("apple", 0)) == previous_stock, "Save snapshots do not share mutable inventory with live play")
	snapshot.produce_boxes = [{"crop_id":"","count":0}]
	snapshot.produce_box_tiles = [[29,17]]
	game._load_state(snapshot)
	check(game.produce_boxes.size() == game.produce_box_tiles.size(), "Short legacy crate layouts restore matching box data")
	game._interaction_target()
	game.free()
	await process_frame
	await process_frame
	print("Steam Deck playability: %d failures" % failures)
	quit(1 if failures else 0)
