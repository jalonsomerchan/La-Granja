extends SceneTree

const Scene = preload("res://scenes/main.tscn")
const Items = preload("res://scripts/item_database.gd")
const Saves = preload("res://scripts/save_manager.gd")
const Farm = preload("res://scripts/farming_rules.gd")
var game: Node
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame: int in range(5): await process_frame

func tap(button: JoyButton) -> void:
	for pressed: bool in [true,false]:
		var event := InputEventJoypadButton.new(); event.button_index = button; event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func find_control(identity: String) -> Control:
	for control: Control in game.menu_nav.controls:
		if String(control.get_meta("menu_id","")) == identity: return control
	return null

func run() -> void:
	root.size = Vector2i(1280,800)
	# Every resource and crafted object has an original transparent sprite.
	check(Items.DATA.size() == 12 and Items.ICONS.size() == 12, "All twelve item types have real icons")
	for item: String in Items.DATA:
		var image: Image = Items.ICONS[item].get_image()
		check(image.get_size() == Vector2i(64,64) and image.get_used_rect().has_area() and not image.get_used_rect().has_point(Vector2i.ZERO), "Item sprite is visible, transparent and 64x64: " + item)
	# Crafting is atomic, validates all ingredients, and rejects malformed quantities.
	var stock: Dictionary = {"wood":15,"fiber":20,"clay":15,"stone":5,"coal":10,"iron_ore":15}
	var original: Dictionary = stock.duplicate(true)
	check(not Items.craft("plank",0,stock).ok and not Items.craft("plank",100,stock).ok and not Items.craft("missing",1,stock).ok, "Invalid crafting requests are rejected")
	check(not Items.craft("brick",1,{"clay":3,"stone":1}).ok, "Missing fuel cannot be skipped")
	check(stock == original, "Rejected crafting and recipe checks never consume stock")
	var result: Dictionary = Items.craft("plank",5,stock)
	check(result.ok and result.amount == 10 and result.inventory.wood == 0 and stock.wood == 15, "Five batches consume exact ingredients in an independent transaction")
	game = Scene.instantiate(); root.add_child(game)
	await settle(); await settle()
	game.set_process(false); game.at_title = false; game._close_modal()
	game.props.clear(); game.plots.clear(); game.inventory = {}; game.inventory_slots.clear(); game.quality_stock.clear()
	game.player_pos = Vector2(592,624); game.facing = Vector2.UP
	game.mouse_aim_active = false; game.energy = 100.0; game.action_cooldown = 0.0
	# Chopping/mining/cutting gathers directly, including old-save rock variants.
	for variant: int in range(4):
		game.props.assign([{"tile":Vector2i(18,18),"kind":"rock","variant":variant,"hp":1}])
		game._hit_prop(Vector2i(18,18),"rock")
	check(game.inventory.stone == 12 and game.inventory.clay == 2 and game.inventory.coal == 2 and game.inventory.iron_ore == 2, "All four rock types yield their correct stone and minerals")
	var mined: Dictionary = game.inventory.duplicate(true)
	game._hit_prop(Vector2i(18,18),"rock")
	check(game.inventory == mined, "Exhausted rock cannot duplicate drops")
	for kind: String in ["tree","stump","weed"]:
		game.props.assign([{"tile":Vector2i(18,18),"kind":kind,"variant":0,"hp":1}])
		game._hit_prop(Vector2i(18,18),"weed" if kind == "weed" else "tree")
	check(game.inventory.wood == 7 and game.inventory.fiber == 1, "Wood and fiber are automatically collected")
	for item: String in game.inventory: check(game.inventory_slots.has(item), "Collected resource gets a backpack slot: " + item)
	game.props.clear()
	# Native A operates craft buttons; both pages retain usable, visible controls.
	game.inventory = original.duplicate(true)
	game._open_modal("inventory"); await settle()
	find_control("crafting").grab_focus(); await tap(JOY_BUTTON_A)
	check(game.modal == "crafting", "Crafting is reachable from the backpack with the controller")
	find_control("craft:plank:5").grab_focus(); await tap(JOY_BUTTON_A)
	check(game.inventory.plank == 10 and game.inventory.wood == 0 and game.inventory_slots.has("plank"), "Controller crafting deposits result in the backpack")
	check(game.modal_feedback.text.contains("Tablón"), "Crafting shows its result inside the menu")
	for control: Control in game.menu_nav.controls:
		if String(control.get_meta("menu_id","")).begins_with("craft:"): check(game.modal_scroll.get_global_rect().encloses(control.get_global_rect()), "Craft buttons remain visible with feedback shown")
	var crafted: Dictionary = game.inventory.duplicate(true)
	game._craft_item("plank",5)
	check(game.inventory == crafted, "A stale repeated craft cannot consume nonexistent materials")
	await tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(game.crafting_page == 1 and find_control("craft:iron_bar:1") != null, "R1 reaches the remaining recipes")
	for recipe: String in ["iron_bar","fertilizer"]: game._craft_item(recipe,1)
	game._craft_item("rope",1); game._craft_item("brick",1); game._craft_item("fence",1)
	check(game.inventory.fence == 2 and game.inventory.fertilizer == 3 and game.inventory.iron_bar == 1, "All recipe chains produce usable objects")
	# Sell precise quantities, only at a market, without touching other stocks.
	game._close_modal(); game.player_pos = Vector2(600,624)
	var coins: int = game.coins; var before_sale: Dictionary = game.inventory.duplicate(true)
	game._sell_material("fence",1)
	check(game.coins == coins and game.inventory == before_sale, "Materials cannot be sold remotely")
	game.player_pos = Vector2(976,550); game.inventory_item_id = "fence"; game._open_modal("item"); await settle()
	find_control("sell_material:1").grab_focus(); await tap(JOY_BUTTON_A)
	check(game.inventory.fence == 1 and game.coins == coins+12 and game.inventory.fertilizer == 3, "Controller sells one chosen resource at its displayed value")
	game._sell_material("fence",99)
	check(game.inventory.fence == 0 and game.coins == coins+24, "Oversized sales clamp to stock")
	game._sell_material("fence",-1)
	check(game.coins == coins+24, "Selling an empty stack never duplicates money")
	game._add_produce("apple",2,"excelente")
	var fiber: int = game.inventory.fiber
	game._sell_all_produce()
	check(game.inventory.fiber == fiber and game.inventory.iron_bar == 1, "Sell harvest still retains all materials")
	# Fertilizer works once per crop and survives watering, growth and a save/load.
	game._close_modal(); game.player_pos = Vector2(592,624); game.action_cooldown = 0.0; game.energy = 100.0
	game.plots["18,18"] = {"soil":"tilled","crop_id":"turnip","growth":1,"watered":false,"wilted":false,"dry_days":0}
	var fertilizer: int = game.inventory.fertilizer
	check(not game._use_backpack_item("fertilizer",Vector2i(35,35)) and game.inventory.fertilizer == fertilizer, "Distant uses do not consume materials")
	game._equip_backpack_item("fertilizer")
	await tap(JOY_BUTTON_A)
	check(game.plots["18,18"].get("fertilized",false) and game.inventory.fertilizer == fertilizer-1, "Equipped fertilizer applies through the real A action")
	check(not game._use_backpack_item("fertilizer",Vector2i(18,18)) and game.inventory.fertilizer == fertilizer-1, "A plot cannot consume fertilizer twice")
	game.selected_tool = 1; game.action_cooldown = 0.0; game._use_tool_at(Vector2i(18,18))
	check(game.plots["18,18"].watered and game.plots["18,18"].fertilized, "Watering preserves fertilizer")
	game.plots["18,18"] = Farm.daily_growth(game.plots["18,18"],false)
	check(game.plots["18,18"].fertilized and game.plots["18,18"].soil == "fertile", "Daily growth keeps the quality bonus")
	var regrowth: Dictionary = Farm.harvest({"soil":"fertile","fertilized":true,"growth":6,"wilted":false},{"days":6,"repeat":2,"yield":2})
	check(not regrowth.plot.has("fertilized") and regrowth.plot.soil != "fertile", "The quality boost is consumed at harvest, including repeat crops")
	# Fences consume stock once, block movement, reject occupied plots and are recoverable.
	game._add_item("fence",2); game.player_pos = Vector2(656,656); game.facing = Vector2.DOWN; game.action_cooldown = 0.0
	game._equip_backpack_item("fence")
	await tap(JOY_BUTTON_A)
	check(game.placed_items.get("20,21","") == "fence" and game.inventory.fence == 1, "A places a crafted fence on free owned land")
	check(game._blocked(Vector2(656,688)), "Placed fence blocks the player's movement")
	check(not game._use_backpack_item("fence",Vector2i(20,21)) and game.inventory.fence == 1, "Occupied placement does not consume another fence")
	check(not game._use_backpack_item("fence",Vector2i(18,18)), "Objects cannot cover a planted crop")
	var snapshot: Dictionary = Saves.decode_game(Saves.encode_game(game._pack_state()))
	game._load_state(snapshot)
	check(game.placed_items.get("20,21","") == "fence" and game.plots["18,18"].fertilized and game.selected_item_id == "fence", "Crafted objects, equipped item and fertilized soil survive a save/load")
	game._hit_prop(Vector2i(20,21),"tree")
	check(not game.placed_items.has("20,21") and game.inventory.fence == 2 and not game._blocked(Vector2(656,688)), "The axe returns the whole fence to the backpack and clears collision")
	# Advanced upgrades actually use the crafted components advertised in recipes.
	game.selected_tool = 0; game.tool_levels.Azada = 2; game.coins = 1000
	for item: String in ["wood","stone","plank","rope","iron_bar"]: game.inventory[item] = 10
	game._upgrade_tool()
	check(game.tool_levels.Azada == 3 and game.inventory.plank == 8 and game.inventory.rope == 9 and game.inventory.iron_bar == 9, "Advanced tool upgrades consume crafted parts")
	var after_upgrade: Dictionary = game.inventory.duplicate(true)
	game.inventory.iron_bar = 0; game._upgrade_tool()
	check(game.tool_levels.Azada == 3 and game.inventory.wood == after_upgrade.wood, "Failed upgrade does not partly consume materials")
	if "--screenshots" in OS.get_cmdline_user_args(): await screenshots()
	game.free(); await settle()
	print("Materials and crafting: %d failures" % failures)
	quit(1 if failures else 0)

func screenshot(name: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/materials-review/%s.png" % name)
	check(Rect2(0,0,1280,800).encloses(game.modal_panel.get_global_rect()), "Material interface fits Steam Deck: " + name)

func screenshots() -> void:
	game._close_modal(); game.last_input_was_gamepad = true
	game.inventory = {"wood":72,"stone":46,"fiber":33,"clay":19,"coal":12,"iron_ore":8,"plank":14,"rope":6,"brick":8,"iron_bar":4,"fertilizer":9,"fence":5,"apple":12,"turnip_seed":10}
	game.inventory_slots.clear(); game.inventory_filter = 0; game.inventory_page = 0
	game._open_modal("inventory"); await screenshot("backpack")
	game.crafting_page = 1; game._open_modal("crafting"); await screenshot("crafting")
	find_control("craft:fertilizer:1").grab_focus(); await tap(JOY_BUTTON_A); await screenshot("crafted")
	game.player_pos = Vector2(976,550); game.inventory_item_id = "wood"; game._open_modal("item"); await screenshot("selling")
	game._close_modal(); game.player_pos = Vector2(656,656); game._use_backpack_item("fence",Vector2i(20,21)); game.queue_redraw()
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/materials-review/placed-fence.png")
