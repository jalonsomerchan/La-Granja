extends SceneTree

const Scene = preload("res://scenes/main.tscn")
const Backpack = preload("res://scripts/backpack_layout.gd")
const Saves = preload("res://scripts/save_manager.gd")
const Crops = preload("res://scripts/crop_database.gd")
var game: Node
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame: int in range(4): await process_frame

func tap(button: JoyButton) -> void:
	for pressed: bool in [true,false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func key(code: Key) -> void:
	for pressed: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func cell(index: int) -> Control:
	for control: Control in game.menu_nav.controls:
		if int(control.get_meta("slot_index",-1)) == index: return control
	return null

func _run() -> void:
	root.size = Vector2i(1280,800)
	# Stable manual positions, automatic free slots and unlimited pages.
	var slots: Array[String] = Backpack.synchronize(["wood","","apple","apple","gone"],{"wood":8,"apple":3,"pear":2})
	check(slots[0] == "wood" and slots[1] == "pear" and slots[2] == "apple" and slots[3] == "", "Synchronization keeps manual positions and removes duplicate/stale entries")
	var stock: Dictionary = {}
	for index: int in range(60): stock["item_%d" % index] = 1
	check(Backpack.synchronize([],stock).size() == 72, "Backpack grows beyond the old vehicle capacity")
	check(not Backpack.swap(slots,-1,0) and not Backpack.swap(slots,23,0), "Invalid and empty sources cannot swap")
	game = Scene.instantiate()
	root.add_child(game)
	await settle()
	await settle()
	game.set_process(false)
	game.at_title = false
	game._close_modal()
	game.inventory = {}
	game.inventory_slots.clear()
	game.quality_stock.clear()
	game._add_item("wood",8)
	game._add_item("turnip_seed",10)
	game._add_produce("apple",7,"excelente")
	game._add_produce("pear",3,"buena")
	game._open_modal("inventory")
	await settle()
	var original_stock: Dictionary = game.inventory.duplicate(true)
	var original_quality: Dictionary = game.quality_stock.duplicate(true)
	# D-pad has a real six-column layout; X/A moves or swaps whole stacks.
	cell(0).grab_focus()
	await tap(JOY_BUTTON_DPAD_RIGHT)
	check(int(root.gui_get_focus_owner().get_meta("slot_index",-1)) == 1, "D-pad right advances one column")
	await tap(JOY_BUTTON_DPAD_DOWN)
	check(int(root.gui_get_focus_owner().get_meta("slot_index",-1)) == 7, "D-pad down advances one six-slot row")
	cell(2).grab_focus()
	await tap(JOY_BUTTON_X)
	check(game.inventory_move_from == 2, "X picks up the focused stack")
	await tap(JOY_BUTTON_DPAD_RIGHT)
	await tap(JOY_BUTTON_A)
	check(game.inventory_slots[2] == "pear" and game.inventory_slots[3] == "apple", "A swaps occupied slots")
	check(game.inventory == original_stock and game.quality_stock == original_quality, "Reordering preserves every count and quality tier")
	await tap(JOY_BUTTON_X)
	await tap(JOY_BUTTON_B)
	check(game.modal == "inventory" and game.inventory_move_from == -1 and game.inventory_slots[3] == "apple", "B cancels movement without leaving the bag or changing layout")
	await key(KEY_F)
	cell(12).grab_focus()
	await key(KEY_ENTER)
	check(game.inventory_slots[12] == "apple" and game.inventory_slots[3] == "", "F and Enter move a stack into an empty slot")
	# Drop validation checks origin ownership and stale payloads.
	var target: Control = cell(5)
	var payload: Dictionary = {"type":"farm_backpack_item","owner":game.get_instance_id(),"source":12,"item":"apple"}
	check(target._can_drop_data(Vector2.ZERO,payload), "Mouse drop accepts the current stack")
	var foreign: Dictionary = payload.duplicate(); foreign.owner = -1
	check(not target._can_drop_data(Vector2.ZERO,foreign), "Mouse drop rejects foreign inventory data")
	var stale: Dictionary = payload.duplicate(); stale.item = "wood"
	check(not target._can_drop_data(Vector2.ZERO,stale), "Mouse drop rejects a stale source item")
	target._drop_data(Vector2.ZERO,payload)
	await settle()
	check(game.inventory_slots[5] == "apple" and game.inventory_slots[12] == "", "Dropping with the mouse uses the same safe move operation")
	var manual: Array = game.inventory_slots.duplicate()
	await key(KEY_O)
	check(game.inventory_slots != manual and not game.inventory_undo_layout.is_empty(), "Sorting changes the layout and offers undo")
	await key(KEY_O)
	check(game.inventory_slots == manual and game.inventory == original_stock, "Undo restores the exact manual layout")
	game._add_item("stone",3)
	check(game.inventory_slots[5] == "apple" and game.inventory_slots.has("stone"), "New materials use free slots without disturbing existing positions")
	# Move between pages with triggers while carrying a stack.
	for crop: Dictionary in Crops.all_crops().slice(0,30): game._add_item(String(crop.id)+"_seed",5)
	game._open_modal("inventory")
	await settle()
	var source: int = game.inventory_slots.find("apple")
	cell(source).grab_focus()
	await tap(JOY_BUTTON_X)
	await tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(game.inventory_filter == 0 and game.inventory_move_from == source, "Category changes cannot hide a pending move")
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT; trigger.axis_value = 0.9
	Input.parse_input_event(trigger)
	await settle()
	trigger = trigger.duplicate(); trigger.axis_value = 0.0
	Input.parse_input_event(trigger)
	await settle()
	check(game.inventory_page == 1 and game.inventory_move_from == source, "R2 turns the page while moving a stack")
	cell(30).grab_focus()
	await tap(JOY_BUTTON_A)
	check(game.inventory_slots[30] == "apple" and game.inventory_move_from == -1, "Cross-page swap keeps the item and destination")
	check(Rect2(Vector2.ZERO,Vector2(1280,800)).encloses(game.modal_panel.get_global_rect()), "Backpack fits the Steam Deck viewport")
	for control: Control in game.menu_nav.controls:
		if control.has_meta("slot_index"): check(game.modal_scroll.get_global_rect().encloses(control.get_global_rect()), "Every grid slot fits without scrolling")
	# Persist a deep snapshot through the real atomic save and JSON loader.
	var saved_slots: Array = game.inventory_slots.duplicate()
	var state: Dictionary = game._pack_state()
	check(not state.has("produce_boxes") and not state.has("truck_cargo") and not state.has("carried_crop_count"), "New saves contain one central inventory and no crates or separate cargo")
	check(Saves.save_game_at(state,"/tmp/farm-backpack-test.json"), "Backpack writes an atomic save")
	game.inventory_slots.clear()
	game._load_state(Saves.load_game_from("/tmp/farm-backpack-test.json"))
	check(game.inventory_slots == saved_slots, "Exact manual order survives a file save/load")
	DirAccess.remove_absolute("/tmp/farm-backpack-test.json")
	# Legacy crates were already in inventory; hand and truck goods were separate.
	var legacy: Dictionary = {"inventory":{"apple":3,"wood":8,"turnip_seed":10},"quality_stock":{"apple":{"normal":3}},"carried_crop_id":"pear","carried_crop_count":2,"carried_quality":"buena","produce_boxes":[{"crop_id":"apple","count":3}],"truck_cargo":[{"crop_id":"apple","count":5,"value":300}]}
	game._close_modal()
	game._load_state(legacy)
	check(game.inventory.apple == 8 and game.inventory.pear == 2, "Legacy migration recovers hands and cargo without duplicating boxed stock")
	var price: int = int(Crops.by_id("apple").sell)
	check(game._produce_sale_value("apple") == 3*price+300, "Frozen legacy cargo sale value survives migration")
	check(int(game.quality_stock.pear.buena) == 2, "Legacy hand produce keeps its quality")
	state = game._pack_state()
	game._load_state(Saves.decode_game(Saves.encode_game(state)))
	check(game.inventory.apple == 8 and game.inventory.pear == 2, "Reloading the migrated save cannot duplicate recovered produce")
	var expected: int = game._produce_sale_value("apple")+game._produce_sale_value("pear")
	var coins: int = game.coins
	game._sell_all_produce()
	check(game.coins == coins+expected and game.inventory.apple == 0 and game.inventory.pear == 0, "Direct backpack sale consumes produce and preserves its full value")
	check(game.inventory.wood == 8 and game.inventory.turnip_seed == 10, "Sale keeps materials and seeds")
	game._sell_all_produce()
	check(game.coins == coins+expected, "Repeated sale cannot duplicate income")
	var repaired: Dictionary = Backpack.migrate({"inventory":{"apple":1},"produce_boxes":[{"crop_id":"apple","count":4}]},game._crop_unit_price)
	check(repaired.inventory.apple == 4, "Incomplete old crate stock recovers only the missing quantity")
	# Native render QA also covers actual mouse drag events, not only drop callbacks.
	if "--screenshots" in OS.get_cmdline_user_args(): await _native_review()
	game.free()
	await settle()
	print("Backpack: %d failures" % failures)
	quit(1 if failures else 0)

func mouse_motion(at: Vector2, relative: Vector2, held: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at; event.global_position = at; event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(event)
	await process_frame

func mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at; event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func _native_review() -> void:
	game.inventory = {"apple":127,"pear":18,"wood":230,"stone":92,"fiber":36,"strawberry_seed":25,"turnip_seed":10,"blueberry":14,"carrot":42,"pumpkin":6}
	game.inventory_slots = Backpack.synchronize([],game.inventory)
	game.inventory_filter = 0; game.inventory_page = 0
	game._open_modal("inventory")
	await settle()
	# Real native GUI drag from slot zero to a free slot.
	var origin: Vector2 = cell(0).get_global_rect().get_center()
	var destination: Vector2 = cell(16).get_global_rect().get_center()
	await mouse_motion(origin,Vector2(12,0))
	await mouse_button(origin,true)
	await mouse_motion(origin+Vector2(24,0),Vector2(24,0),true)
	await mouse_motion(destination,destination-origin-Vector2(24,0),true)
	await mouse_button(destination,false)
	await settle()
	check(game.inventory_slots[16] == "apple" and game.inventory_slots[0] == "", "Real GUI mouse drag moves a stack into its target slot")
	game.last_input_was_gamepad = true
	game._refresh_hud()
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/backpack-review/backpack.png")
	cell(16).grab_focus()
	await tap(JOY_BUTTON_X)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/backpack-review/moving.png")
	await tap(JOY_BUTTON_B)
