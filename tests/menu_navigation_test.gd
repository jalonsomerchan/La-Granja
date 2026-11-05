extends SceneTree

const Scene = preload("res://scenes/main.tscn")
const Crops = preload("res://scripts/crop_database.gd")
var failures: int = 0
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _focused() -> Control:
	return root.gui_get_focus_owner()

func _key() -> String:
	var control := _focused()
	return String(control.get_meta("menu_id", "")) if control != null else ""

func _pad(button: JoyButton, pressed: bool, device: int = 0) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.device = device
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func _tap(button: JoyButton) -> void:
	await _pad(button,true)
	await _pad(button,false)
	await process_frame

func _axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	await process_frame

func _keyboard(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _settle() -> void:
	await process_frame
	await process_frame

func _find(key: String) -> Control:
	for control: Control in game.menu_nav.controls:
		if String(control.get_meta("menu_id", "")) == key: return control
	return null

func _run() -> void:
	root.size = Vector2i(1280,800)
	game = Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	game.at_title = false
	game._close_modal()
	game.inventory.clear()
	game.coins = 100000
	for crop: Dictionary in Crops.all_crops():
		game.inventory[crop.id] = 3
		game.inventory[String(crop.id) + "_seed"] = 10
	game.inventory.wood = 5
	game.inventory.stone = 5
	game.inventory.fiber = 2
	game._open_modal("pause")
	await _settle()
	check(game.menu_nav.controls.size() == 7, "Pause has seven primary options and keeps session actions separate")
	check(game.modal_scroll.get_v_scroll_bar().max_value <= game.modal_scroll.get_v_scroll_bar().page + 1.0, "Pause fits on the Deck screen without scrolling")
	await _tap(JOY_BUTTON_DPAD_DOWN)
	check(_focused() is Button and _focused().text == "Mochila", "D-pad moves exactly one pause option")
	await _tap(JOY_BUTTON_A)
	check(game.modal == "inventory" and _key().begins_with("slot:"), "Inventory opens on a grid slot")
	check(game.inventory_slots.size()-game.inventory_slots.count("") == 243 and game._inventory_page_count() == 11, "All 243 inventory types are reachable across pages")
	check(game.menu_nav.controls.size() == 34, "One readable page contains tabs, paging, 24 slots and actions")
	# Item details return to the same slot and page.
	var pumpkin_slot: int = game.inventory_slots.find("pumpkin")
	game.inventory_page = pumpkin_slot/24
	game._open_modal("inventory")
	await _settle()
	game.menu_nav._focus(_find("slot:%d" % pumpkin_slot))
	await _settle()
	var previous_page: int = game.inventory_page
	await _tap(JOY_BUTTON_A)
	check(game.modal == "item" and game.inventory_item_id == "pumpkin", "A opens the selected crop's details")
	await _tap(JOY_BUTTON_B)
	check(game.modal == "inventory" and _key() == "slot:%d" % pumpkin_slot, "B restores the exact inventory slot")
	check(game.inventory_page == previous_page, "Returning restores the inventory page")
	await _tap(JOY_BUTTON_B)
	check(game.modal == "pause" and _focused().text == "Mochila", "B restores the opener in the parent menu")
	# Native keyboard and Tab navigation use the same confined focus list.
	await _keyboard(KEY_DOWN)
	check(_focused().text.begins_with("Viajar"), "Keyboard arrow navigation moves exactly once")
	await _keyboard(KEY_W)
	check(_focused().text == "Mochila", "WASD also navigates menus")
	await _keyboard(KEY_TAB)
	check(_focused().text.begins_with("Viajar"), "Tab advances within the modal")
	# Stick jitter cannot repeatedly skip items; held directions have a deliberate repeat.
	await _axis(JOY_AXIS_LEFT_Y,0.72)
	var index: int = game.menu_nav.controls.find(_focused())
	await _axis(JOY_AXIS_LEFT_Y,0.76)
	await _axis(JOY_AXIS_LEFT_Y,0.69)
	check(game.menu_nav.controls.find(_focused()) == index, "Analog jitter cannot repeat navigation")
	game.menu_nav.update(0.4)
	check(game.menu_nav.controls.find(_focused()) == index+1, "Holding the stick repeats after the initial delay")
	await _axis(JOY_AXIS_LEFT_Y,0.0)
	var stopped: Control = _focused()
	game.menu_nav.update(0.5)
	check(_focused() == stopped, "Releasing the stick stops repetition")
	# Top/bottom stay in the modal; no hidden HUD button can steal focus.
	game.menu_nav._focus(game.menu_nav.controls.back())
	await _tap(JOY_BUTTON_DPAD_DOWN)
	check(_focused() == game.menu_nav.controls.back(), "Bottom boundary does not jump to Close or the game HUD")
	await _tap(JOY_BUTTON_DPAD_LEFT)
	check(_focused() == game.menu_nav.controls.back(), "Left/right on a vertical list do not escape")
	# Shop controls stay fixed, and disabled purchases are skipped.
	game._close_modal()
	game._choose_shop_season(0)
	await _settle()
	check(_key() == "buy:turnip", "Shop starts on the first purchasable crop")
	var tabs_position: Vector2 = game.modal_tabs.global_position
	game.menu_nav._focus(_find("buy:carrot"))
	await _tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(game.shop_page == 1 and int(_focused().get_meta("page_slot",-1)) == 1, "R1 changes page while preserving the crop row")
	await _tap(JOY_BUTTON_LEFT_SHOULDER)
	check(game.shop_page == 0 and _key() == "buy:carrot", "L1 returns to the previous crop selection")
	var coins: int = game.coins
	await _tap(JOY_BUTTON_A)
	check(game.coins == coins-int(Crops.by_id("carrot").seed) and _key() == "buy:carrot", "Purchase retains crop focus")
	check(game.modal_feedback.visible and game.modal_feedback.text.contains("Zanahoria"), "Purchase feedback is visible inside the menu")
	await _axis(JOY_AXIS_TRIGGER_RIGHT,0.8)
	check(game.shop_season == 1, "R2 switches shop season")
	await _axis(JOY_AXIS_TRIGGER_RIGHT,0.9)
	check(game.shop_season == 1, "Trigger jitter cannot skip multiple seasons")
	await _axis(JOY_AXIS_TRIGGER_RIGHT,0.0)
	game.coins = 0
	game._open_modal("shop")
	await _settle()
	for control: Control in game.menu_nav.controls:
		check(not (control is BaseButton and control.disabled), "Disabled buys are excluded from focus traversal")
	check(game.menu_nav.controls.size() >= 7, "Shop remains navigable when no purchases are affordable")
	check(game.modal_tabs.global_position == tabs_position, "Shop categories stay fixed when content changes")
	# Every inventory category remains reachable, including empty categories.
	game._close_modal()
	game._open_modal("inventory")
	await _settle()
	await _tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(game.inventory_filter == 1, "L1/R1 switch inventory categories")
	for control: Control in game.menu_nav.controls:
		if control.has_meta("slot_index") and not control.item_id.is_empty(): check(control.item_id.ends_with("_seed"), "Seed category only contains seeds")
	var before_page: int = game.inventory_page
	await _axis(JOY_AXIS_TRIGGER_RIGHT,0.8)
	check(game.inventory_page == before_page+1, "Trigger changes inventory page")
	await _axis(JOY_AXIS_TRIGGER_RIGHT,0.0)
	await _settle()
	check(game.modal_scroll.get_global_rect().encloses(_focused().get_global_rect()), "Selected grid slot is fully visible")
	game.inventory.clear()
	game._choose_inventory_filter(2)
	await _settle()
	check(_focused() != null and game.inventory_slots.size() == 24, "Empty categories retain accessible slots and actions")
	# Read-only menus are scrollable with the same controls.
	for field_index: int in range(48): game.plots["%d,%d" % [18+field_index%8,16+field_index/8]] = {"crop_id":"turnip","growth":1,"watered":true,"wilted":false}
	game._open_modal("field_status")
	await _settle()
	check(_focused() == game.modal_close_button, "Read-only pages focus the back button")
	await _axis(JOY_AXIS_RIGHT_Y,0.9)
	game.menu_nav.update(0.6)
	await _settle()
	check(game.modal_scroll.scroll_vertical > 0, "Controls documentation can be read with right stick")
	await _axis(JOY_AXIS_RIGHT_Y,0.0)
	# A press cannot activate an option on a new screen before its release.
	game._close_modal()
	game._open_modal("pause")
	await _settle()
	await _pad(JOY_BUTTON_A,true)
	game._open_modal("settings")
	var assisted: bool = game.assisted_actions
	await _pad(JOY_BUTTON_A,false)
	check(game.modal == "settings" and game.assisted_actions == assisted, "Opening a menu cancels stale confirmation presses")
	# Fresh confirmations always start at Cancel.
	game.confirmation_back = "pause"
	game._open_modal("confirm_new")
	await _settle()
	check(_focused().text.begins_with("Cancelar"), "Confirmations default to cancel")
	await _tap(JOY_BUTTON_DPAD_DOWN)
	game._open_modal("confirm_new")
	check(_focused().text.begins_with("Cancelar"), "Reopening confirmation never remembers the destructive option")
	await _tap(JOY_BUTTON_B)
	check(game.modal == "pause", "B cancels a confirmation without ending the game")
	game.menu_nav._focus(game.menu_nav.controls[0])
	await _pad(JOY_BUTTON_DPAD_DOWN,true,2)
	await _pad(JOY_BUTTON_DPAD_DOWN,false,2)
	check(_focused().text == "Mochila", "An external controller can navigate, regardless of device index")
	await _axis(JOY_AXIS_LEFT_Y,0.8)
	var before_focus_loss: Control = _focused()
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	game.menu_nav.update(1.0)
	check(_focused() == before_focus_loss, "Focus loss stops held menu navigation")
	await _axis(JOY_AXIS_LEFT_Y,0.0)
	await _axis(JOY_AXIS_LEFT_Y,0.8)
	var before_disconnect: Control = _focused()
	game._on_joy_connection_changed(2,false)
	game.menu_nav.update(1.0)
	check(_focused() == before_disconnect, "Controller disconnect stops menu repetition")
	await _axis(JOY_AXIS_LEFT_Y,0.0)
	game.free()
	await _settle()
	print("Menu navigation: %d failures" % failures)
	quit(1 if failures else 0)
