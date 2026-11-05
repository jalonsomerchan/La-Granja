extends Node2D

const Play = preload("res://scripts/playability_rules.gd")
const Places = preload("res://scripts/travel_world.gd")
const TILE: int = 32
const MAP_SIZE := Vector2i(54, 40)
const TREE_DRAW_SIZE := Vector2(64,80)
const GROUND_PROP_DRAW_SIZE := Vector2(48,48)
const Spacing = preload("res://scripts/world_spacing.gd")
# Visual bounds, rather than just the tile containing an object's base.
const FIXED_OBJECT_RECTS: Array[Rect2] = [
	Rect2(632,368,144,144), # House.
	Rect2(604,456,28,34), # Barrel.
	Rect2(770,474,36,30), # Sacks.
	Rect2(772,434,48,30), # Bench.
	Rect2(920,428,112,96), # Market stand.
	Rect2(980,546,56,60), # Well.
	Rect2(96,1036,40,48), # Road signs.
	Rect2(1592,1036,40,48),
]
const CropDB = preload("res://scripts/crop_database.gd")
const Rules = preload("res://scripts/farming_rules.gd")
const Fruit = preload("res://scripts/fruit_rules.gd")
const FRUIT_TEXTURES: Dictionary = {
	"apple": [preload("res://assets/sprites/fruiting/apple_empty.png"), preload("res://assets/sprites/fruiting/apple_ripe.png")],
	"pear": [preload("res://assets/sprites/fruiting/pear_empty.png"), preload("res://assets/sprites/fruiting/pear_ripe.png")],
	"berry": [preload("res://assets/sprites/fruiting/berry_empty.png"), preload("res://assets/sprites/fruiting/berry_ripe.png")],
	"blueberry": [preload("res://assets/sprites/fruiting/blueberry_empty.png"), preload("res://assets/sprites/fruiting/blueberry_ripe.png")],
	"raspberry": [preload("res://assets/sprites/fruiting/raspberry_empty.png"), preload("res://assets/sprites/fruiting/raspberry_ripe.png")],
}
var fruit_rng := RandomNumberGenerator.new()
const Economy = preload("res://scripts/economy_rules.gd")
const Saves = preload("res://scripts/save_manager.gd")
const FARMER_TEXTURE: Texture2D = preload("res://assets/generated/farmer_walk_32x48.png")
const TREE_TEXTURES: Dictionary = {"oak":preload("res://assets/sprites/trees/oak.png"),"apple":preload("res://assets/sprites/trees/apple.png")}
const GROUND_PROP_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/rock_cluster.png"),preload("res://assets/sprites/props/boulder.png"),preload("res://assets/sprites/props/stone_pair.png"),
	preload("res://assets/sprites/props/berry_bush.png"),preload("res://assets/sprites/props/flower_bush.png"),preload("res://assets/sprites/props/fern_bush.png"),
	preload("res://assets/sprites/props/tall_grass.png"),preload("res://assets/sprites/props/daisies.png"),preload("res://assets/sprites/props/thistle.png")
]
const PRODUCE_CRATE_TEXTURE: Texture2D = preload("res://assets/sprites/props/produce_crate.png")
const FARMHOUSE_TEXTURE: Texture2D = preload("res://assets/sprites/buildings/farmhouse.png")
const SURFACE_ATLAS: Texture2D = preload("res://assets/sprites/terrain/surface_variants.png")
const FARM_OBJECTS: Dictionary = {
	"fence_horizontal": preload("res://assets/sprites/props/fence_horizontal.png"),
	"fence_vertical": preload("res://assets/sprites/props/fence_vertical.png"),
	"barrel": preload("res://assets/sprites/props/barrel.png"),
	"grain_sacks": preload("res://assets/sprites/props/grain_sacks.png"),
	"wooden_sign": preload("res://assets/sprites/props/wooden_sign.png"),
	"well": preload("res://assets/sprites/props/well.png"),
	"market_stand": preload("res://assets/sprites/props/market_stand.png"),
	"bench": preload("res://assets/sprites/props/bench.png")
}
const FARM_TRUCK_TEXTURES: Dictionary = {
	"down": preload("res://assets/sprites/vehicles/farm_truck_down.png"),
	"up": preload("res://assets/sprites/vehicles/farm_truck_up.png"),
	"left": preload("res://assets/sprites/vehicles/farm_truck_left.png"),
	"right": preload("res://assets/sprites/vehicles/farm_truck_right.png")
}
const TERRAIN_ATLAS: Texture2D = preload("res://assets/sprites/terrain/terrain_variants.png")
const PLAYER_ACTIONS: Texture2D = preload("res://assets/sprites/animations/player_tool_actions.png")
const PLAYER_ACTIONS_LEFT: Texture2D = preload("res://assets/sprites/animations/player_tool_actions_left.png")
const PLAYER_ACTION_ROWS: Dictionary = {"chop":0,"dig":1,"water":2,"cut":3,"mine":4,"plant":5,"harvest":5}
const SFX: Dictionary = {
	"soil": preload("res://assets/audio/soil.wav"), "water": preload("res://assets/audio/water.wav"),
	"harvest": preload("res://assets/audio/harvest.wav"), "wood": preload("res://assets/audio/wood.wav"),
	"stone": preload("res://assets/audio/stone.wav")
}

var location: String = "farm"
var truck_location: String = "farm"
var at_title: bool = false
var modal_close_button: Button
var modal_shade: ColorRect
var travel_button: Button
var confirmation_back: String = "pause"
var road_exit_cooldown: float = 0.0

var player_pos := Vector2(704, 560)
var facing := Vector2.RIGHT
var aim_stick := Vector2.ZERO
var mouse_aim_active: bool = false
var mouse_target_tile := Vector2i.ZERO
var last_input_was_gamepad: bool = false
var speed: float = 158.0
var camera_zoom: float = 1.35
var assisted_actions: bool = true
var repeat_actions: bool = true
var relaxed_clock: bool = true
var haptics: bool = true
var action_cooldown: float = 0.0
var repeat_elapsed: float = 0.0
var repeat_tile := Vector2i(-1, -1)
var repeat_kind: String = ""
var hud_elapsed: float = 0.0
var shop_page: int = 0
const SHOP_PAGE_SIZE: int = 5
var tool_buttons: Array[Button] = []
var objective_label: Label
var action_label: Label
var modal_scroll: ScrollContainer
var modal_footer: Label
var settings_back: String = "pause"
var sleeping: bool = false
var sleep_transition_time: float = 0.0
var sleep_day_advanced: bool = false
var carried_crop_id: String = ""
var carried_crop_count: int = 0
var carried_quality: String = "normal"
var produce_boxes: Array[Dictionary] = [
	{"crop_id":"", "count":0}, {"crop_id":"", "count":0}, {"crop_id":"", "count":0}
]
var produce_box_tiles: Array[Vector2i] = [Vector2i(29,17), Vector2i(29,18), Vector2i(29,19)]
var moving_box_index: int = -1
var mouse_dragging_box: bool = false
var truck_pos := Vector2(1152, 624)
var truck_facing := Vector2.LEFT
var truck_driving: bool = false
var truck_cargo: Array[Dictionary] = []
const TRUCK_CAPACITY: int = 6
var walk_phase: float = 0.0
var tool_charge: float = 0.0
var move_vector := Vector2.ZERO
var selected_tool: int = 0
var tool_names: Array[String] = ["Azada", "Regadera", "Semillas", "Hacha", "Pico", "Guadaña"]
var selected_seed_id: String = "turnip"
var seed_order: Array[String] = CropDB.crop_ids()
var shop_season: int = -1
var crop_icon_cache: Dictionary = {}
var tool_levels: Dictionary = {"Azada": 1, "Regadera": 1, "Hacha": 1, "Pico": 1, "Guadaña": 1}
var inventory: Dictionary = {"turnip_seed": 5, "carrot_seed": 4, "potato_seed": 3, "wood": 0, "stone": 0}
var quality_stock: Dictionary = {}
var plots: Dictionary = {}
var particles: Array[Dictionary] = []
var props: Array[Dictionary] = []
var sprite_content_bounds: Dictionary = {}
var coins: int = 180
var energy: float = 100.0
var water: int = 12
var max_water: int = 12
var day: int = 1
var season_index: int = 0
var minute: float = 360.0
var weather: String = "Soleado"
var rain_today: bool = false
var owned_parcels: int = 1
var xp: Dictionary = {"Agricultura": 0, "Tala": 0, "Minería": 0, "Recolección": 0, "Comercio": 0}
var modal: String = ""
var toast: String = ""
var toast_time: float = 0.0
var action_time: float = 0.0
var player_animation: String = "idle"
var saved_once: bool = false
var sfx_player: AudioStreamPlayer

var canvas: CanvasLayer
var hud: Control
var day_label: Label
var money_label: Label
var energy_bar: ProgressBar
var water_label: Label
var tool_label: Label
var hint_label: Label
var toast_label: Label
var seed_picker_button: Button
var deposit_produce_button: Button
var modal_panel: PanelContainer
var modal_title: Label
var modal_body: VBoxContainer

const SEASONS: Array[String] = ["Primavera", "Verano", "Otoño", "Invierno"]
const WEATHER: Array[String] = ["Soleado", "Nublado", "Lluvia", "Tormenta", "Nieve"]
const COLORS := {
	"grass_a": Color("709b4d"), "grass_b": Color("7da956"), "grass_c": Color("84af5d"),
	"soil": Color("815239"), "soil_light": Color("a2704b"), "soil_dark": Color("5f3d30"),
	"wet": Color("52675a"), "fertile": Color("65483e"), "water": Color("63aeb2")
}

func _ready() -> void:
	at_title = true
	Input.set_use_accumulated_input(false)
	sfx_player = AudioStreamPlayer.new(); sfx_player.volume_db = -8.0; add_child(sfx_player)
	_make_world()
	_build_hud()
	_open_modal("title")
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Ignore stick drift: it must not hide a mouse cursor or steal menu focus.
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.3):
		last_input_was_gamepad = true
		mouse_aim_active = false
	elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 2.0):
		last_input_was_gamepad = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if last_input_was_gamepad else Input.MOUSE_MODE_VISIBLE
	if sleeping: return
	var key_repeat: bool = event is InputEventKey and event.echo
	if key_repeat: return
	if modal != "":
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game"):
			_back_from_modal()
			get_viewport().set_input_as_handled()
		elif modal == "shop" and (event.is_action_pressed("tool_prev") or event.is_action_pressed("tool_next")):
			_change_shop_page(-1 if event.is_action_pressed("tool_prev") else 1)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause_game"):
		_open_modal("pause")
	elif event.is_action_pressed("inventory"):
		_open_modal("inventory")
	elif event.is_action_pressed("travel"):
		_open_modal("travel")
	elif event.is_action_pressed("sleep"):
		_sleep()
	elif event.is_action_pressed("select_seed"):
		_open_seed_selector()
	elif event.is_action_pressed("tool_next"):
		_select_tool((selected_tool + 1) % tool_names.size())
	elif event.is_action_pressed("tool_prev"):
		_select_tool(posmod(selected_tool - 1, tool_names.size()))
	elif event.is_action_pressed("seed_next"):
		_cycle_seed(1)
	elif event.is_action_pressed("seed_prev"):
		_cycle_seed(-1)
	elif event.is_action_pressed("interact"):
		if event is InputEventKey: mouse_aim_active = false
		_primary_action()
		repeat_elapsed = 0.0
	elif event.is_action_pressed("use_tool"):
		if event is InputEventKey:
			mouse_aim_active = false
			aim_stick = Vector2.ZERO
		if truck_driving: _park_truck()
		elif _can_quick_load(): _quick_load_truck()
		else: _use_selected_tool()
		repeat_elapsed = 0.0
	elif event.is_action_pressed("charge_tool"):
		tool_charge = 0.01
	elif event.is_action_released("charge_tool"):
		if tool_charge > 0.0: _use_selected_tool()
	elif event.is_action_pressed("ui_cancel"):
		if moving_box_index >= 0: _drop_carried_box()
		else: _open_modal("pause")
	else:
		return
	get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if at_title or sleeping: return
	if modal != "":
		if event.is_action_pressed("ui_cancel"): _back_from_modal()
		return
	if not truck_driving and _handle_box_mouse(event): return
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.3):
		mouse_aim_active = false
		last_input_was_gamepad = true
	elif event is InputEventKey:
		mouse_aim_active = false
		aim_stick = Vector2.ZERO
		last_input_was_gamepad = false
	if event is InputEventMouseMotion:
		mouse_aim_active = true
		var world_mouse: Vector2 = player_pos + (event.position - get_viewport_rect().size * 0.5) / camera_zoom
		mouse_target_tile = Vector2i(floori(world_mouse.x / TILE), floori(world_mouse.y / TILE))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not truck_driving:
			mouse_aim_active = true
			var world_mouse: Vector2 = player_pos + (event.position - get_viewport_rect().size * 0.5) / camera_zoom
			mouse_target_tile = Vector2i(floori(world_mouse.x / TILE), floori(world_mouse.y / TILE))
			_use_selected_tool()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP: _set_zoom(camera_zoom + 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _set_zoom(camera_zoom - 0.1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6: _select_tool(event.keycode - KEY_1)
		elif event.keycode in [KEY_EQUAL, KEY_KP_ADD, KEY_PLUS]: _set_zoom(camera_zoom + 0.1)
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]: _set_zoom(camera_zoom - 0.1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(modal_panel) and not at_title and not sleeping:
		if modal == "": _open_modal("pause")
		tool_charge = 0.0

func _back_from_modal() -> void:
	if modal.begins_with("confirm_") or modal == "river_rest": _cancel_confirmation()
	elif modal == "workshop": _open_modal("shop")
	elif modal in ["settings", "controls"]: _open_modal(settings_back)
	elif at_title: _open_modal("title")
	else: _close_modal()

func _work_action(tile: Vector2i) -> Dictionary:
	if not _tile_in_reach(tile) or moving_box_index >= 0 or truck_driving: return {}
	for box_tile: Vector2i in produce_box_tiles:
		if box_tile == tile: return {}
	for bounds: Rect2 in FIXED_OBJECT_RECTS:
		if bounds.has_point(Vector2(tile * TILE) + Vector2(16, 16)): return {}
	var prop: Dictionary = {}
	for item: Dictionary in props:
		if item.tile == tile:
			prop = item
			if not Fruit.species(prop).is_empty() and int(prop.get("fruit_count", 0)) > 0:
				return {"harvest": true, "label": "Recoger fruta"}
			break
	var plot: Dictionary = plots.get(_tile_key(tile), {})
	var crop: Dictionary = CropDB.by_id(String(plot.get("crop_id", "")))
	var seed: Dictionary = CropDB.by_id(selected_seed_id)
	var has_seed: bool = not seed.is_empty() and seed.season == SEASONS[season_index] and int(inventory.get(selected_seed_id + "_seed", 0)) > 0
	# Fruit plants are preserved by the assisted action; X remains the explicit tool.
	if not prop.is_empty() and not Fruit.species(prop).is_empty(): return {}
	return Play.work(plot, prop, _can_use_land(tile), has_seed, not crop.is_empty() and Rules.is_ready(plot, crop))

func _primary_target() -> Dictionary:
	var context := _interaction_target()
	if not assisted_actions or moving_box_index >= 0 or truck_driving: return context
	var work := _work_action(_target_tile())
	if work.is_empty(): return context
	# Close fixtures take precedence; aiming directly at a work tile chooses it.
	if not context.is_empty() and context.action not in ["harvest", "stump"] and context.has("point"):
		if player_pos.distance_to(context.point) < 48.0 or (Vector2(_target_tile() * TILE) + Vector2(16,16)).distance_to(context.point) < 36.0:
			return context
	work["action"] = "work"
	work["tile"] = _target_tile()
	return work

func _primary_action(repeating: bool = false) -> void:
	if at_title or sleeping or modal != "" or action_cooldown > 0.0: return
	var target := _primary_target()
	if target.is_empty():
		if not repeating: _show_toast("Apunta a una casilla o acércate a un objeto.")
		return
	if repeating and target.action not in ["work", "harvest", "stump"]: return
	if repeating and target.action == "work" and repeat_kind != String(target.label) and repeat_tile == target.tile: return
	if target.action == "work":
		var tile: Vector2i = target.tile
		repeat_kind = String(target.label)
		repeat_tile = tile
		if target.has("harvest"): _harvest(tile)
		else:
			selected_tool = int(target.tool)
			_use_selected_tool()
	else: _interact()
	action_cooldown = 0.3

func _update_repeated_action(delta: float) -> void:
	if tool_charge > 0.0 or not repeat_actions: return
	if not Input.is_action_pressed("interact") and not Input.is_action_pressed("use_tool"):
		repeat_elapsed = 0.0
		return
	repeat_elapsed += delta
	if repeat_elapsed < 0.38 or action_cooldown > 0.0: return
	repeat_elapsed = 0.0
	if Input.is_action_pressed("interact"): _primary_action(true)
	elif not truck_driving and not _can_quick_load(): _use_selected_tool()

func _make_world() -> void:
	props.clear()
	_repair_box_layout()
	var obstacles := _layout_obstacles()
	var rng := RandomNumberGenerator.new()
	rng.seed = 88127
	# Un conjunto de objetos legibles y diseñados a mano alrededor de la parcela.
	for item: Dictionary in [
		{"tile":Vector2i(19,15),"kind":"tree","hp":3,"variant":0}, {"tile":Vector2i(17,23),"kind":"tree","hp":3,"variant":2},
		{"tile":Vector2i(25,13),"kind":"tree","hp":3,"variant":1}, {"tile":Vector2i(28,24),"kind":"rock","hp":2,"variant":1},
		{"tile":Vector2i(15,26),"kind":"rock","hp":2,"variant":2}, {"tile":Vector2i(24,25),"kind":"weed","hp":1,"variant":0},
		{"tile":Vector2i(25,26),"kind":"bush","hp":1,"variant":1}
	]:
		if _can_place_prop(item, obstacles): props.append(item)
	for y: int in range(40):
		for x: int in range(54):
			var tile := Vector2i(x, y)
			if Vector2(x * TILE + 16, y * TILE + 16).distance_to(Vector2(1152, 624)) < 100.0:
				continue
			if x < 4 or y < 3 or x > 49 or y > 36:
				continue
			if _inside_starting_field(tile) or _is_path(tile):
				continue
			if rng.randf() < 0.22:
				var roll: float = rng.randf()
				var kind: String = "tree" if roll < 0.44 else ("rock" if roll < 0.68 else ("bush" if roll < 0.84 else "weed"))
				var candidate := {"tile": tile, "kind": kind, "hp": 3 if kind == "tree" else 2, "variant": rng.randi_range(0, 3)}
				if _can_place_prop(candidate, obstacles): props.append(candidate)
	for prop: Dictionary in props:
		Fruit.initialize(prop, fruit_rng)

func _handle_box_mouse(event: InputEvent) -> bool:
	if location != "farm": return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		last_input_was_gamepad = false
		if event.pressed:
			var world_mouse: Vector2 = player_pos + (event.position - get_viewport_rect().size * 0.5) / camera_zoom
			for index: int in range(produce_box_tiles.size()):
				var center := Vector2(produce_box_tiles[index] * TILE) + Vector2(16, 16)
				if center.distance_to(world_mouse) <= 34.0 and player_pos.distance_to(center) <= 80.0 and carried_crop_count == 0 and moving_box_index < 0:
					moving_box_index = index
					mouse_dragging_box = true
					_set_box_tile_from_mouse(world_mouse, index)
					_show_toast("Arrastra la caja; suéltala en una casilla libre.")
					return true
		else:
			if mouse_dragging_box:
				var dropped_index := moving_box_index
				mouse_dragging_box = false
				moving_box_index = -1
				_show_toast("Caja colocada · E para guardar frutas")
				queue_redraw()
				return dropped_index >= 0
	if event is InputEventMouseMotion and mouse_dragging_box and moving_box_index >= 0:
		var world_mouse: Vector2 = player_pos + (event.position - get_viewport_rect().size * 0.5) / camera_zoom
		_set_box_tile_from_mouse(world_mouse, moving_box_index)
		return true
	return false

func _set_box_tile_from_mouse(world_pos: Vector2, index: int) -> void:
	var tile := Vector2i(floori(world_pos.x / TILE), floori(world_pos.y / TILE))
	if player_pos.distance_to(Vector2(tile * TILE) + Vector2(16,16)) <= 80.0 and _can_place_box(tile, index):
		produce_box_tiles[index] = tile
		queue_redraw()

func _can_place_box(tile: Vector2i, index: int) -> bool:
	if tile.x <= 0 or tile.y <= 0 or tile.x >= MAP_SIZE.x - 1 or tile.y >= MAP_SIZE.y - 1: return false
	if tile == Vector2i(floori(player_pos.x / TILE), floori(player_pos.y / TILE)): return false
	if _is_path(tile) or plots.has(_tile_key(tile)): return false
	var bounds := _box_bounds(tile)
	for obstacle: Rect2 in _layout_obstacles(index):
		if bounds.intersects(obstacle): return false
	for prop: Dictionary in props:
		if bounds.grow(2).intersects(_prop_bounds(prop)): return false
	for other_index: int in range(produce_box_tiles.size()):
		if other_index != index and produce_box_tiles[other_index] == tile: return false
	return true

func _box_bounds(tile: Vector2i) -> Rect2:
	return Rect2(Vector2(tile * TILE) + Vector2(1,4), Vector2(30,25))

func _repair_box_layout() -> void:
	for index: int in range(produce_box_tiles.size()):
		var origin := produce_box_tiles[index]
		if _can_place_box(origin, index): continue
		var placed := false
		for radius: int in range(1,MAP_SIZE.x):
			for dy: int in range(-radius,radius+1):
				for dx: int in range(-radius,radius+1):
					if maxi(absi(dx),absi(dy)) != radius: continue
					var tile := origin + Vector2i(dx,dy)
					if _can_place_box(tile, index):
						produce_box_tiles[index] = tile
						placed = true
						break
				if placed: break
			if placed: break

func _prop_bounds(prop: Dictionary) -> Rect2:
	var p := Vector2(Vector2i(prop.tile) * TILE)
	if prop.kind == "stump": return Rect2(p + Vector2(-2,4), Vector2(36,28))
	var key := "%s:%d" % [prop.kind, int(prop.variant)]
	if not sprite_content_bounds.has(key):
		var species: String = Fruit.species(prop)
		var content: Rect2
		if not species.is_empty():
			content = Rect2(FRUIT_TEXTURES[species][0].get_image().get_used_rect())
			content = content.merge(Rect2(FRUIT_TEXTURES[species][1].get_image().get_used_rect()))
		elif prop.kind == "tree":
			content = Rect2(TREE_TEXTURES["oak"].get_image().get_used_rect())
		else:
			var index := posmod(int(prop.variant),3) + (6 if prop.kind == "weed" else 0)
			content = Rect2(GROUND_PROP_TEXTURES[index].get_image().get_used_rect())
		var scale := TREE_DRAW_SIZE / Vector2(80,96) if prop.kind == "tree" else GROUND_PROP_DRAW_SIZE / Vector2(64,64)
		var draw_size := TREE_DRAW_SIZE if prop.kind == "tree" else GROUND_PROP_DRAW_SIZE
		content.position = content.position * scale + Vector2(16-draw_size.x*0.5,32-draw_size.y)
		content.size *= scale
		sprite_content_bounds[key] = content
	var result: Rect2 = sprite_content_bounds[key]
	result.position += p
	return result

func _layout_obstacles(ignore_box_index: int = -1) -> Array[Rect2]:
	var result: Array[Rect2] = FIXED_OBJECT_RECTS.duplicate()
	result.append(Rect2(39*TILE,4*TILE,9*TILE,9*TILE)) # Stream and banks.
	if owned_parcels < 2: result.append(Rect2(927,638,40,48)) # Land sign.
	for x: int in range(17,29):
		if x < 20 or x > 22: result.append(Rect2(x*TILE-1,27*TILE,34,24))
	for y: int in range(15,27):
		result.append(Rect2(16*TILE+8,y*TILE-2,20,36))
		if owned_parcels < 2: result.append(Rect2(29*TILE-28,y*TILE-2,20,36))
	if owned_parcels >= 2:
		for x: int in range(29,40):
			result.append(Rect2(x*TILE-1,14*TILE,34,24))
			result.append(Rect2(x*TILE-1,27*TILE,34,24))
		for y: int in range(15,27): result.append(Rect2(40*TILE-28,y*TILE-2,20,36))
	for y: int in range(MAP_SIZE.y):
		for x: int in range(MAP_SIZE.x):
			if _is_path(Vector2i(x,y)): result.append(Rect2(x*TILE,y*TILE,TILE,TILE))
	for key: Variant in plots:
		var parts := String(key).split(",")
		if parts.size() == 2: result.append(Rect2(int(parts[0])*TILE,int(parts[1])*TILE,TILE,TILE))
	for index: int in range(produce_box_tiles.size()):
		if index != ignore_box_index: result.append(_box_bounds(produce_box_tiles[index]))
	var truck_size := Vector2(116,62) if absf(truck_facing.x) > absf(truck_facing.y) else Vector2(78,98)
	if truck_location == "farm": result.append(Rect2(truck_pos - truck_size * 0.5, truck_size).grow(8))
	return result

func _can_place_prop(prop: Dictionary, obstacles: Array[Rect2]) -> bool:
	var bounds := _prop_bounds(prop).grow(3)
	if not Rect2(TILE,TILE,(MAP_SIZE.x-2)*TILE,(MAP_SIZE.y-2)*TILE).encloses(bounds): return false
	for obstacle: Rect2 in obstacles:
		if bounds.intersects(obstacle): return false
	for other: Dictionary in props:
		if bounds.intersects(_prop_bounds(other)): return false
	return true

func _repair_prop_layout() -> void:
	var sources: Array[Dictionary] = props.duplicate()
	var displaced: Array[Dictionary] = []
	props.clear()
	var obstacles := _layout_obstacles()
	var space := Spacing.new()
	for obstacle: Rect2 in obstacles: space.occupy(obstacle)
	# Keep legal positions first, so loading does not shuffle the whole map.
	for prop: Dictionary in sources:
		if _prop_fits_space(prop, space):
			props.append(prop)
			space.occupy(_prop_bounds(prop))
		else: displaced.append(prop)
	var unplaced: Array[Dictionary] = []
	for prop: Dictionary in displaced:
		var origin: Vector2i = prop.tile
		var placed := false
		for radius: int in range(1,MAP_SIZE.x):
			for dy: int in range(-radius,radius+1):
				for dx: int in range(-radius,radius+1):
					if maxi(absi(dx),absi(dy)) != radius: continue
					var tile := origin + Vector2i(dx,dy)
					if tile.x < 1 or tile.y < 1 or tile.x >= MAP_SIZE.x-1 or tile.y >= MAP_SIZE.y-1: continue
					prop.tile = tile
					if _prop_fits_space(prop, space):
						props.append(prop)
						space.occupy(_prop_bounds(prop))
						placed = true
						break
				if placed: break
			if placed: break
		if not placed: unplaced.append(prop)
	if not unplaced.is_empty(): _repack_prop_layout(sources, obstacles)

func _repack_prop_layout(sources: Array[Dictionary], obstacles: Array[Rect2]) -> void:
	props.clear()
	var space := Spacing.new()
	for obstacle: Rect2 in obstacles: space.occupy(obstacle)
	sources.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_size := _prop_bounds(a).size
		var b_size := _prop_bounds(b).size
		return a_size.x * a_size.y > b_size.x * b_size.y)
	for prop: Dictionary in sources:
		var placed := false
		for y: int in range(1,MAP_SIZE.y-1):
			for x: int in range(1,MAP_SIZE.x-1):
				prop.tile = Vector2i(x,y)
				if _prop_fits_space(prop, space):
					props.append(prop)
					space.occupy(_prop_bounds(prop))
					placed = true
					break
			if placed: break
		if not placed: push_warning("No free space for scenery")

func _prop_fits_space(prop: Dictionary, space: RefCounted) -> bool:
	var bounds := _prop_bounds(prop).grow(3)
	return Rect2(TILE,TILE,(MAP_SIZE.x-2)*TILE,(MAP_SIZE.y-2)*TILE).encloses(bounds) and space.can_fit(bounds)

func _inside_starting_field(tile: Vector2i) -> bool:
	return tile.x >= 17 and tile.x <= 28 and tile.y >= 14 and tile.y <= 26

func _process(delta: float) -> void:
	action_cooldown = maxf(0.0, action_cooldown - delta)
	road_exit_cooldown = maxf(0.0, road_exit_cooldown - delta)
	if sleeping:
		sleep_transition_time += delta
		if sleep_transition_time >= 1.15 and not sleep_day_advanced:
			_finish_sleep_day()
		if sleep_transition_time >= 2.6:
			sleeping = false
			sleep_transition_time = 0.0
			_show_toast("¡Buenos días! Día %d · %s" % [day, SEASONS[season_index]])
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0 and is_instance_valid(toast_label): toast_label.visible = false
	if action_time > 0.0:
		action_time = maxf(0.0, action_time - delta)
	else:
		player_animation = "idle"
	for index: int in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		particle.life = float(particle.life) - delta
		particle.pos = Vector2(particle.pos) + Vector2(particle.vel) * delta
		particle.vel = Vector2(particle.vel) + Vector2(0,24) * delta
		if float(particle.life) <= 0.0: particles.remove_at(index)
		else: particles[index] = particle
	if modal == "" and not sleeping:
		_update_movement(delta)
		_update_clock(delta)
		# Descansar quieto recupera energía despacio, sin saltarse el avance del día.
		if move_vector.length() <= 0.12 and action_time <= 0.0:
			energy = minf(100.0, energy + 0.2 * delta)
		if Input.is_action_pressed("charge_tool"):
			tool_charge = minf(1.4, tool_charge + delta)
		_update_repeated_action(delta)
	hud_elapsed += delta
	if hud_elapsed >= 0.1:
		hud_elapsed = 0.0
		_refresh_hud()
	queue_redraw()

func _update_movement(delta: float) -> void:
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length() > 1.0: move = move.normalized()
	move_vector = move
	if move.length() > 0.12:
		aim_stick = Vector2.ZERO
		facing = move.normalized()
		if truck_driving:
			if absf(move.x) > absf(move.y): truck_facing = Vector2.RIGHT if move.x > 0.0 else Vector2.LEFT
			else: truck_facing = Vector2.DOWN if move.y > 0.0 else Vector2.UP
		walk_phase += delta * 11.0
		if action_time <= 0.0: player_animation = "walk"
		var candidate: Vector2 = player_pos + move * (speed * (1.85 if truck_driving else (0.8 if moving_box_index >= 0 else 1.15))) * delta
		if not _blocked(candidate, moving_box_index):
			player_pos = candidate
		else:
			# Slide along obstacles instead of sticking on diagonal approaches.
			var x_step := Vector2(candidate.x, player_pos.y)
			if not _blocked(x_step, moving_box_index): player_pos = x_step
			var y_step := Vector2(player_pos.x, candidate.y)
			if not _blocked(y_step, moving_box_index): player_pos = y_step
		if truck_driving: truck_pos = player_pos
	if _try_road_exit(move): return
	# El stick derecho coloca el objetivo de trabajo sobre una casilla, sin cursor de ratón.
	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim.length() > 0.35:
		mouse_aim_active = false
		aim_stick = aim.normalized()
		facing = aim_stick
	if moving_box_index >= 0 and not mouse_dragging_box:
		var carried_box_tile := _target_tile()
		if _tile_in_reach(carried_box_tile) and _can_place_box(carried_box_tile, moving_box_index): produce_box_tiles[moving_box_index] = carried_box_tile

func _blocked(pos: Vector2, ignore_box_index: int = -1) -> bool:
	if location != "farm":
		if Places.blocked(location, pos): return true
		return not truck_driving and truck_location == location and Rect2(truck_pos - Vector2(50, 25), Vector2(100, 50)).has_point(pos)
	var tile := Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))
	if tile.x < 0 or tile.y < 0 or tile.x >= MAP_SIZE.x or tile.y >= MAP_SIZE.y: return true
	if Rect2(Vector2(640,416),Vector2(128,88)).has_point(pos): return true
	if Rect2(Vector2(29*TILE,14*TILE+13),Vector2(95,62)).has_point(pos): return true
	if Rect2(Vector2(31*TILE-6,18*TILE+5),Vector2(44,21)).has_point(pos): return true
	var parked_truck_size := Vector2(116, 62) if absf(truck_facing.x) > absf(truck_facing.y) else Vector2(78, 98)
	if not truck_driving and truck_location == location and Rect2(truck_pos - parked_truck_size * 0.5 + Vector2(8, 8), parked_truck_size - Vector2(16, 16)).has_point(pos): return true
	if tile.x >= 40 and tile.x <= 46 and tile.y >= 5 and tile.y <= 11: return true
	for prop: Dictionary in props:
		if prop.kind in ["tree", "rock", "bush", "stump", "house"] and prop.tile == tile:
			return true
	for index: int in range(produce_box_tiles.size()):
		if index != ignore_box_index and produce_box_tiles[index] == tile: return true
	return false

func _is_path(tile: Vector2i) -> bool:
	if tile.x >= 0 and tile.x < MAP_SIZE.x and tile.y >= Places.ROAD_FIRST_ROW and tile.y <= Places.ROAD_LAST_ROW: return true
	if _inside_starting_field(tile) or tile.y < 9 or tile.y > 37: return false
	var center_x: int = int(21.0 - sin(float(tile.y) * 0.23) * 2.7)
	return abs(tile.x - center_x) <= 1

func _set_zoom(value: float) -> void:
	camera_zoom = clampf(value, 0.85, 2.2)
	_refresh_hud()

func _update_clock(delta: float) -> void:
	minute += delta * (3.0 if relaxed_clock else 6.0)
	if minute >= 1440.0:
		minute = 360.0
		_advance_day()

func _advance_day() -> void:
	for prop: Dictionary in props:
		Fruit.advance_day(prop, fruit_rng)
	day += 1
	if day > 28:
		day = 1
		season_index = (season_index + 1) % 4
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 1907 + season_index * 331
	weather = "Nieve" if season_index == 3 and rng.randf() < 0.36 else WEATHER[rng.randi_range(0, 3)]
	rain_today = weather in ["Lluvia", "Tormenta"]
	for key: Variant in plots.keys():
		var plot: Dictionary = plots[key]
		var crop: Dictionary = CropDB.by_id(String(plot.get("crop_id", "")))
		if crop.is_empty(): continue
		if crop.season != SEASONS[season_index]:
			plot["wilted"] = true
		else:
			plot = Rules.daily_growth(plot, rain_today)
		plots[key] = plot
	energy = 100.0
	water = mini(max_water, water + 5)
	minute = 360.0
	_show_toast("Día %d · %s · %s" % [day, SEASONS[season_index], weather])
	_refresh_hud()

func _target_tile() -> Vector2i:
	if mouse_aim_active: return mouse_target_tile
	var direction := facing
	if aim_stick.length() > 0.35: direction = aim_stick
	if direction.length() < 0.1: direction = Vector2.RIGHT
	var offset := Vector2i(roundi(direction.x), roundi(direction.y))
	if absf(direction.x) > absf(direction.y): offset.y = 0
	else: offset.x = 0
	return Vector2i(floori(player_pos.x / TILE), floori(player_pos.y / TILE)) + offset

func _use_selected_tool() -> void:
	if at_title or sleeping or modal != "" or truck_driving or action_cooldown > 0.0: return
	if moving_box_index >= 0:
		_show_toast("Deja la caja antes de usar herramientas."); return
	if tool_names[selected_tool] == "Regadera":
		var context := _interaction_target()
		if not context.is_empty() and context.action == "water":
			tool_charge = 0.0
			_refill_water(); return
	if location != "farm":
		_show_toast("Aquí puedes explorar e interactuar con A / E."); return
	var center: Vector2i = _target_tile()
	if not _tile_in_reach(center):
		tool_charge = 0.0
		_show_toast("Acércate a la casilla para usar la herramienta."); return
	var level: int = int(tool_levels.get(tool_names[selected_tool], 1))
	var radius: int = 1 if tool_charge >= 0.55 and level >= 2 else 0
	var cells: Array[Vector2i] = [center]
	if radius > 0:
		for y: int in range(-radius, radius + 1):
			for x: int in range(-radius, radius + 1):
				if x == 0 and y == 0: continue
				if tool_names[selected_tool] == "Azada" or tool_names[selected_tool] == "Regadera": cells.append(center + Vector2i(x,y))
	for tile: Vector2i in cells:
		_use_tool_at(tile, 128.0 if radius > 0 else 80.0)
	tool_charge = 0.0
	action_cooldown = 0.3

func _tile_in_reach(tile: Vector2i, reach: float = 80.0) -> bool:
	return location == "farm" and tile.x >= 0 and tile.y >= 0 and tile.x < MAP_SIZE.x and tile.y < MAP_SIZE.y and player_pos.distance_to(Vector2(tile * TILE) + Vector2(16,16)) <= reach

func _use_tool_at(tile: Vector2i, reach: float = 80.0) -> void:
	if not _tile_in_reach(tile, reach):
		_show_toast("Acércate a la casilla para usar la herramienta."); return
	if moving_box_index >= 0: _show_toast("Deja la caja antes de trabajar."); return
	for prop: Dictionary in props:
		if prop.tile == tile and tool_names[selected_tool] in ["Azada", "Semillas", "Regadera"]:
			_show_toast("Retira primero el objeto con la herramienta adecuada."); return
	for box_tile: Vector2i in produce_box_tiles:
		if box_tile == tile: _show_toast("Mueve primero la caja de esa casilla."); return
	for bounds: Rect2 in FIXED_OBJECT_RECTS:
		if bounds.has_point(Vector2(tile * TILE) + Vector2(16,16)):
			_show_toast("Ese espacio está ocupado por un objeto."); return
	if _is_path(tile): _show_toast("El camino está limpio y no se puede trabajar."); return
	if energy <= 0.0: _show_toast("Estás agotado. Descansa un poco."); return
	var key := _tile_key(tile)
	var tool: String = tool_names[selected_tool]
	var plot: Dictionary = plots.get(key, {})
	if not String(plot.get("crop_id", "")).is_empty():
		if tool == "Regadera" and not bool(plot.get("wilted", false)):
			pass # Regar nunca debe cosechar por accidente.
		else:
			_show_toast("Utiliza la acción principal para cosechar o retirar plantas secas.")
			return
	if tool == "Azada":
		if not _can_use_land(tile): _show_toast("Ese terreno aún no es tuyo."); return
		if not plot.is_empty() and (not String(plot.get("crop_id", "")).is_empty() or String(plot.get("soil", "")) != "cleared"):
			_show_toast("Limpia primero la hierba de esa casilla."); return
		if plot.is_empty(): plot = {"soil":"tilled","crop_id":"","growth":0,"watered":false,"dry_days":0,"wilted":false}
		else: plot.soil = "tilled"
		plots[key] = plot
		energy = maxf(0.0, energy - 3); xp.Agricultura += 2; _action("dig"); _show_toast("Tierra preparada")
	elif tool == "Regadera":
		if water <= 0: _show_toast("La regadera está vacía. Pulsa E junto al pozo."); return
		if plot.is_empty(): _show_toast("Primero prepara la tierra."); return
		if bool(plot.get("watered", false)): _show_toast("Esta casilla ya está regada."); return
		if String(plot.get("soil", "")) == "cleared": _show_toast("Prepara primero la tierra con la azada."); return
		plot["watered"] = true; plot["soil"] = "wet" if String(plot.get("crop_id", "")) != "" else "tilled"; plots[key] = plot
		water -= 1; energy = maxf(0.0, energy - 1.2); _action("water"); _show_toast("Una gota de vida para tu cultivo")
	elif tool == "Semillas":
		if plot.is_empty() or not String(plot.get("crop_id", "")).is_empty(): _show_toast("Prepara una casilla vacía con la azada."); return
		var choice := _seed_choice()
		var crop: Dictionary = CropDB.by_id(choice)
		if crop.is_empty(): return
		if crop.season != SEASONS[season_index]: _show_toast("Las semillas de %s esperan a %s." % [crop.name, crop.season.to_lower()]); return
		if not Rules.can_plant(String(plot.get("soil", "")), crop, SEASONS[season_index], false): return
		var seed_key := choice + "_seed"
		if int(inventory.get(seed_key, 0)) <= 0: _show_toast("No quedan semillas. Visita la tienda."); return
		inventory[seed_key] -= 1
		# Sembrar no cuenta como riego: la semilla debe recibir agua para crecer.
		plot["crop_id"] = choice; plot["growth"] = 0; plot["watered"] = false; plot["wilted"] = false; plots[key] = plot
		energy = maxf(0.0, energy - 1.5); xp.Agricultura += 3; _action("plant"); _show_toast("Sembraste %s · riégala cada día para que crezca" % crop.name)
	elif tool == "Hacha":
		_hit_prop(tile, "tree")
	elif tool == "Pico":
		_hit_prop(tile, "rock")
	elif tool == "Guadaña":
		_hit_prop(tile, "weed")
	_refresh_hud()

func _seed_choice() -> String:
	return selected_seed_id

func _cycle_seed(direction: int) -> void:
	seed_order.clear()
	for crop: Dictionary in _seed_catalog(): seed_order.append(String(crop.id))
	var start: int = seed_order.find(selected_seed_id)
	for offset: int in range(1, seed_order.size() + 1):
		var index: int = posmod(start + offset * direction, seed_order.size())
		var seed_id: String = seed_order[index]
		if int(inventory.get(seed_id + "_seed", 0)) > 0:
			selected_seed_id = seed_id
			_show_toast("Semillas seleccionadas: %s ×%d" % [CropDB.by_id(seed_id).name, int(inventory[seed_id + "_seed"])])
			_refresh_hud()
			return
	_show_toast("No tienes más variedades de semillas.")

func _hit_prop(tile: Vector2i, expected: String) -> void:
	if not _tile_in_reach(tile): return
	if energy < 1.0: _show_toast("Estás agotado. Descansa un poco."); return
	for index: int in range(props.size()):
		var prop: Dictionary = props[index]
		if prop.tile != tile: continue
		if expected == "weed" and prop.kind in ["weed", "bush"]:
			props.remove_at(index)
			inventory["fiber"] = int(inventory.get("fiber", 0)) + 1; _show_toast("Maleza retirada · fibra +1")
			xp.Recolección += 2; energy -= 1; _action("cut"); return
		if expected == "tree" and prop.kind in ["tree", "stump"]:
			prop.hp = int(prop.hp) - tool_levels.Hacha
			energy = maxf(0.0, energy - 4.0 / float(tool_levels.Hacha)); xp.Tala += 4; _action("chop")
			if prop.hp <= 0:
				props.remove_at(index)
				var wood := 2 if prop.kind == "stump" else 5
				inventory["wood"] = int(inventory.get("wood", 0)) + wood
				if prop.kind == "tree": props.append({"tile":tile,"kind":"stump","hp":2,"variant":0})
				_show_toast("Madera +%d" % wood)
			else: props[index] = prop; _show_toast("¡Toc! La madera cede.")
			return
		if expected == "rock" and prop.kind == "rock":
			prop.hp = int(prop.hp) - tool_levels.Pico
			energy = maxf(0.0, energy - 3.0 / float(tool_levels.Pico)); xp.Minería += 4; _action("mine")
			if prop.hp <= 0:
				props.remove_at(index); inventory["stone"] = int(inventory.get("stone", 0)) + 3; _show_toast("Piedra +3")
			else: props[index] = prop; _show_toast("¡Clink! Queda un poco más.")
			return
		_show_toast("Usa el hacha para madera, el pico para roca o la guadaña para maleza."); return
	if expected == "weed" and _can_use_land(tile) and not plots.has(_tile_key(tile)):
		plots[_tile_key(tile)] = {"soil":"cleared","crop_id":"","growth":0,"watered":false,"dry_days":0,"wilted":false}
		energy -= 1.0; xp.Recolección += 1; _action("cut"); _show_toast("Hierba alta retirada · suelo despejado"); return
	_show_toast("No hay nada que trabajar aquí.")

func _harvest(tile: Vector2i) -> bool:
	if not _tile_in_reach(tile): return false
	if moving_box_index >= 0:
		_show_toast("Deja la caja antes de recoger la cosecha."); return true
	if energy < 1.0:
		_show_toast("Estás agotado. Descansa un poco."); return true
	if _harvest_fruit(tile): return true
	var key := _tile_key(tile)
	if not plots.has(key): return false
	var plot: Dictionary = plots[key]
	var crop: Dictionary = CropDB.by_id(String(plot.get("crop_id", "")))
	if crop.is_empty(): return false
	if bool(plot.get("wilted", false)):
		plots[key] = {"soil":"tilled","crop_id":"","growth":0,"watered":false,"dry_days":0,"wilted":false}; _show_toast("La planta se marchitó; la tierra aún sirve."); return true
	if not Rules.is_ready(plot, crop): _show_toast("%s · %d/%d días" % [crop.name, plot.growth, crop.days]); return true
	var result: Dictionary = Rules.harvest(plot, crop)
	var quality: String = "Normal"
	var quality_roll: float = randf() + minf(float(xp.Agricultura) / 500.0, 0.18) + (0.15 if String(plot.soil) == "fertile" else 0.0)
	if quality_roll >= 0.94: quality = "Excepcional"
	elif quality_roll >= 0.78: quality = "Excelente"
	elif quality_roll >= 0.48: quality = "Buena"
	var product_key: String = String(crop.id)
	_add_produce(product_key, int(result.yield), quality.to_lower())
	if not result.plot.is_empty(): plots[key] = result.plot
	else: plots[key] = {"soil":"tilled","crop_id":"","growth":0,"watered":false,"dry_days":0,"wilted":false}
	energy = maxf(0.0, energy - 1.0); xp.Agricultura += 8; _action("harvest"); _show_toast("%s +%d · en la mochila" % [crop.name, result.yield]); _refresh_hud(); return true

func _harvest_fruit(tile: Vector2i) -> bool:
	for prop: Dictionary in props:
		if prop.tile != tile: continue
		var species: String = Fruit.species(prop)
		if species.is_empty(): return false
		if not _near_world_point(Vector2(tile * TILE) + Vector2(16,16), 80.0):
			_show_toast("Acércate para recoger la fruta."); return true
		Fruit.initialize(prop, fruit_rng)
		var crop: Dictionary = CropDB.by_id(String(Fruit.SPECIES[species].product))
		if int(prop.get("fruit_count", 0)) <= 0:
			_show_toast("%s · próxima fruta en %d días" % [crop.name, int(prop.fruit_days)]); return true
		if moving_box_index >= 0:
			_show_toast("Deja la caja antes de recoger fruta."); return true
		if energy < 1.0:
			_show_toast("Estás agotado. Descansa un poco."); return true
		var amount: int = int(prop.fruit_count)
		_add_produce(String(crop.id), amount, "normal")
		Fruit.reset(prop, fruit_rng)
		energy = maxf(0.0, energy - 1.0)
		xp.Recolección += 5
		_action("harvest")
		_show_toast("%s +%d · en la mochila" % [crop.name, amount])
		_refresh_hud()
		queue_redraw()
		return true
	return false

# One resolver drives both E/X and the contextual hint. Only reachable objects
# participate; explicit aim breaks ties without letting a distant cursor act remotely.
func _interaction_target() -> Dictionary:
	if moving_box_index >= 0:
		if _box_can_reach_truck(moving_box_index) and int(produce_boxes[moving_box_index].get("count",0)) > 0:
			return {"action":"load_carried_box", "label":"Cargar caja en la camioneta"}
		return {"action":"drop_box", "label":"Soltar caja"}
	if truck_driving:
		var market := Vector2(960,464) if location == "farm" else Vector2(560,560)
		if location != "river" and _near_world_point(market, 190.0) and not truck_cargo.is_empty():
			return {"action":"sell", "label":"Vender carga"}
		return {"action":"park", "label":"Aparcar y bajar"}
	var candidates: Array[Dictionary] = []
	if truck_location == location:
		_add_interaction(candidates, "truck", "Subir a la camioneta", truck_pos, 100.0)
	if location == "farm":
		_add_interaction(candidates, "sleep", "Dormir y guardar", Vector2(704,504), 100.0)
		_add_interaction(candidates, "shop", "Abrir tienda", Vector2(976,510), 100.0)
		_add_interaction(candidates, "water", "Llenar regadera", Vector2(1008,592), 85.0)
		if owned_parcels == 1:
			_add_interaction(candidates, "land", "Ver ampliación de terreno", Vector2(947,664), 65.0)
		for index: int in range(produce_box_tiles.size()):
			var label := "Guardar cosecha" if not _available_produce().is_empty() and int(produce_boxes[index].get("count",0)) < 5 else "Recoger caja"
			if _box_can_reach_truck(index) and int(produce_boxes[index].get("count",0)) > 0:
				label = "Cargar caja en la camioneta"
			_add_interaction(candidates, "box", label, Vector2(produce_box_tiles[index] * TILE) + Vector2(16,16), 80.0, index)
		for key: String in plots:
			if String(plots[key].get("crop_id", "")).is_empty(): continue
			var tile := _key_tile(key)
			_add_interaction(candidates, "harvest", "Recoger / examinar cultivo", Vector2(tile * TILE) + Vector2(16,16), 64.0, -1, tile)
		for prop: Dictionary in props:
			if not Fruit.species(prop).is_empty():
				_add_interaction(candidates, "harvest", "Recoger / examinar fruta", Vector2(prop.tile * TILE) + Vector2(16,16), 80.0, -1, prop.tile)
			elif prop.kind == "stump":
				_add_interaction(candidates, "stump", "Retirar tocón", Vector2(prop.tile * TILE) + Vector2(16,16), 64.0, -1, prop.tile)
	else:
		if location == "town":
			_add_interaction(candidates, "shop", "Abrir tienda", Vector2(560,544), 150.0)
			_add_interaction(candidates, "water", "Llenar regadera en la fuente", Vector2(896,624), 115.0)
		else:
			_add_interaction(candidates, "water", "Llenar regadera en el río", Vector2(875,718), 125.0)
			_add_interaction(candidates, "rest", "Descansar junto al río", Vector2(576,660), 95.0)
	var best: Dictionary = {}
	for candidate: Dictionary in candidates:
		if best.is_empty() or float(candidate.score) < float(best.score): best = candidate
	return best

func _add_interaction(candidates: Array[Dictionary], action: String, label: String, point: Vector2, reach: float, index: int = -1, tile: Vector2i = Vector2i(-1,-1)) -> void:
	var distance := player_pos.distance_to(point)
	if distance > reach: return
	var target_center := Vector2(_target_tile() * TILE) + Vector2(16,16)
	var aimed := target_center.distance_to(point) <= 24.0
	candidates.append({"action":action, "label":label, "index":index, "tile":tile, "point":point, "score":distance - (32.0 if aimed else 0.0)})

func _box_can_reach_truck(index: int) -> bool:
	return truck_location == location and (Vector2(produce_box_tiles[index] * TILE) + Vector2(16,16)).distance_to(truck_pos) <= 150.0

func _interact() -> void:
	if at_title or sleeping or modal != "": return
	var target := _interaction_target()
	if target.is_empty():
		_show_toast("Acércate a un objeto o apunta a una casilla cercana."); return
	match String(target.action):
		"drop_box": _drop_carried_box()
		"load_carried_box": _load_box_into_truck(moving_box_index)
		"sell": _sell_truck_cargo()
		"park": _park_truck()
		"truck":
			truck_driving = true
			player_pos = truck_pos
			_show_toast("Camioneta en marcha · A / E interactúa · X / Espacio aparca.")
		"box":
			var index := int(target.index)
			if _box_can_reach_truck(index) and int(produce_boxes[index].get("count",0)) > 0: _load_box_into_truck(index)
			elif not _available_produce().is_empty() and int(produce_boxes[index].get("count",0)) < 5: _deliver_to_box(index)
			else: _pick_up_box(index)
		"harvest": _harvest(target.tile)
		"stump": _hit_prop(target.tile, "tree")
		"sleep": _sleep()
		"water": _refill_water()
		"shop", "land", "travel": _open_modal(String(target.action))
		"rest":
			confirmation_back = ""
			_open_modal("river_rest")
			_populate_confirmation("¿Descansar junto al río?", "Pasarán 20 minutos y recuperarás 15 de energía.", _rest_at_river)
			var first: Control = _first_focusable(modal_body)
			if first != null and is_inside_tree(): first.grab_focus()
	_refresh_hud()
	queue_redraw()

func _refill_water() -> void:
	if water >= max_water:
		_show_toast("La regadera ya está llena · %d/%d" % [water, max_water]); return
	water = max_water
	_action("water")
	_show_toast("Regadera llena · %d/%d" % [water, max_water])
	_refresh_hud()

func _park_truck() -> void:
	# Check several exits against scenery, boxes and the parked vehicle itself.
	truck_driving = false
	for offset: Vector2 in [Vector2(-90,0), Vector2(90,0), Vector2(0,90), Vector2(0,-90), Vector2(-90,90), Vector2(90,90)]:
		var exit_pos := truck_pos + offset
		if not _blocked(exit_pos):
			player_pos = exit_pos
			_show_toast("Camioneta aparcada · A / E para volver a subir.")
			return
	truck_driving = true
	_show_toast("Aparca donde haya espacio para bajar.")

func _load_box_into_truck(index: int) -> void:
	if index < 0 or index >= produce_boxes.size(): return
	var box: Dictionary = produce_boxes[index]
	var count := int(box.get("count", 0))
	if count <= 0:
		_show_toast("La caja está vacía.")
		return
	if truck_cargo.size() >= TRUCK_CAPACITY:
		_show_toast("La camioneta está llena · capacidad %d cajas." % TRUCK_CAPACITY)
		return
	var crop_id := String(box.get("crop_id", ""))
	var crop: Dictionary = CropDB.by_id(crop_id)
	if crop.is_empty(): return
	var value := _take_box_stock_value(crop_id, count, int(crop.sell))
	truck_cargo.append({"crop_id": crop_id, "count": count, "value": value})
	produce_boxes[index] = {"crop_id":"", "count":0}
	if moving_box_index == index: moving_box_index = -1
	_show_toast("Caja cargada · camioneta %d/%d" % [truck_cargo.size(), TRUCK_CAPACITY])
	_refresh_hud()

func _take_box_stock_value(crop_id: String, amount: int, unit_price: int) -> int:
	var tiers: Dictionary = quality_stock.get(crop_id, {"normal": amount}).duplicate(true)
	var remaining := amount
	var value := 0
	for tier: String in ["excepcional", "excelente", "buena", "normal"]:
		var in_stock := int(tiers.get(tier, 0))
		var taken := mini(remaining, in_stock)
		var multiplier := 1.0
		match tier:
			"buena": multiplier = 1.25
			"excelente": multiplier = 1.6
			"excepcional": multiplier = 2.25
		value += roundi(float(unit_price) * multiplier * taken)
		tiers[tier] = in_stock - taken
		remaining -= taken
		if remaining <= 0: break
	if remaining > 0: value += unit_price * remaining
	var stock: int = int(inventory.get(crop_id, 0))
	inventory[crop_id] = maxi(0, stock - amount)
	quality_stock[crop_id] = tiers
	return value

func _sell_truck_cargo() -> void:
	if truck_cargo.is_empty():
		_show_toast("Has llegado al mercadillo, pero la camioneta está vacía.")
		_open_modal("shop")
		return
	var total_value := 0
	var total_count := 0
	for box: Dictionary in truck_cargo:
		total_value += int(box.get("value", 0))
		total_count += int(box.get("count", 0))
	coins += total_value
	xp.Comercio += total_count * 3
	var sold_boxes := truck_cargo.size()
	truck_cargo.clear()
	_show_toast("¡Vendiste %d cajas (%d productos) · +%d ◈!" % [sold_boxes, total_count, total_value])
	_refresh_hud()

func _pick_up_box(index: int) -> void:
	moving_box_index = index
	mouse_dragging_box = false
	var box_center := Vector2(produce_box_tiles[index] * TILE) + Vector2(16,16)
	var toward_box := box_center - player_pos
	if absf(toward_box.x) > absf(toward_box.y): facing = Vector2(signf(toward_box.x), 0)
	else: facing = Vector2(0, signf(toward_box.y))
	var target := _target_tile()
	if _tile_in_reach(target) and _can_place_box(target, index): produce_box_tiles[index] = target
	_show_toast("Caja recogida · muévete y pulsa A / E para soltarla.")

func _drop_carried_box() -> void:
	var target := _target_tile()
	if not _tile_in_reach(target):
		_show_toast("Suelta la caja en una casilla cercana."); return
	if not _can_place_box(target, moving_box_index):
		_show_toast("No cabe ahí. Apunta a una casilla libre y vuelve a pulsar E."); return
	produce_box_tiles[moving_box_index] = target
	moving_box_index = -1
	_show_toast("Caja colocada")

func _find_delivery_box() -> int:
	var best := -1
	var best_score := INF
	for index: int in range(produce_box_tiles.size()):
		var center := Vector2(produce_box_tiles[index] * TILE) + Vector2(16,16)
		var distance := player_pos.distance_to(center)
		if distance > 120.0: continue
		var box: Dictionary = produce_boxes[index]
		var count := int(box.get("count",0))
		var crop_id := String(box.get("crop_id",""))
		if count >= 5 or (count > 0 and _loose_produce(crop_id) <= 0): continue
		var score := distance - (40.0 if count > 0 else 0.0)
		if score < best_score:
			best = index
			best_score = score
	return best

func _near_delivery_area() -> bool:
	if location != "farm": return false
	for box_tile: Vector2i in produce_box_tiles:
		if _near_world_point(Vector2(box_tile * TILE) + Vector2(16,16), 120.0): return true
	return _near_world_point(Vector2(976,510), 120.0)

func _deposit_nearby_produce() -> void:
	if at_title or sleeping or modal != "" or _available_produce().is_empty() or not _near_delivery_area(): return
	var index := _find_delivery_box()
	if index < 0: index = _create_delivery_box()
	if index < 0:
		_show_toast("No encuentro una casilla libre para la caja."); return
	_deliver_to_box(index)

func _create_delivery_box() -> int:
	var origin := Vector2i(floori(player_pos.x / TILE), floori(player_pos.y / TILE))
	for radius: int in range(1,4):
		for dy: int in range(-radius,radius+1):
			for dx: int in range(-radius,radius+1):
				var candidate := origin + Vector2i(dx,dy)
				var index := produce_box_tiles.size()
				if _tile_in_reach(candidate, 120.0) and _can_place_box(candidate, index):
					produce_box_tiles.append(candidate)
					produce_boxes.append({"crop_id":"", "count":0})
					return index
	return -1

func _add_produce(crop_id: String, amount: int, quality: String) -> void:
	inventory[crop_id] = int(inventory.get(crop_id, 0)) + amount
	var tiers: Dictionary = quality_stock.get(crop_id, {})
	tiers[quality] = int(tiers.get(quality, 0)) + amount
	quality_stock[crop_id] = tiers

func _migrate_hand_produce() -> void:
	if carried_crop_count > 0 and not CropDB.by_id(carried_crop_id).is_empty():
		_add_produce(carried_crop_id, carried_crop_count, carried_quality)
	carried_crop_id = ""
	carried_crop_count = 0
	carried_quality = "normal"

func _loose_produce(crop_id: String) -> int:
	return Play.loose_count(crop_id, inventory, produce_boxes)

func _produce_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in inventory:
		if int(inventory[key]) > 0 and not CropDB.by_id(String(key)).is_empty(): ids.append(String(key))
	ids.sort()
	return ids

func _available_produce() -> String:
	var best: String = ""
	for crop_id: String in _produce_ids():
		if _loose_produce(crop_id) > 0 and (best.is_empty() or _loose_produce(crop_id) > _loose_produce(best)):
			best = crop_id
	return best

func _can_quick_load() -> bool:
	if truck_driving or moving_box_index >= 0 or truck_location != location or not _near_world_point(truck_pos, 120.0): return false
	if not _available_produce().is_empty(): return true
	if location == "farm":
		for index: int in range(produce_boxes.size()):
			if _box_can_reach_truck(index) and int(produce_boxes[index].get("count", 0)) > 0: return true
	return false

func _quick_load_truck() -> void:
	if not _can_quick_load(): return
	var before: int = truck_cargo.size()
	if location == "farm":
		for index: int in range(produce_boxes.size()):
			if truck_cargo.size() >= TRUCK_CAPACITY: break
			if _box_can_reach_truck(index) and int(produce_boxes[index].get("count", 0)) > 0: _load_box_into_truck(index)
	for crop_id: String in _produce_ids():
		var crop: Dictionary = CropDB.by_id(crop_id)
		while _loose_produce(crop_id) > 0 and truck_cargo.size() < TRUCK_CAPACITY:
			var count: int = mini(5, _loose_produce(crop_id))
			var value: int = _take_box_stock_value(crop_id, count, int(crop.sell))
			truck_cargo.append({"crop_id": crop_id, "count": count, "value": value})
	_show_toast("%d cajas cargadas · camioneta %d/%d" % [truck_cargo.size() - before, truck_cargo.size(), TRUCK_CAPACITY])
	_refresh_hud()

func _deliver_to_box(index: int) -> void:
	if index < 0 or index >= produce_boxes.size(): return
	_migrate_hand_produce()
	var box: Dictionary = produce_boxes[index]
	var box_count: int = int(box.get("count", 0))
	var crop_id: String = String(box.get("crop_id", ""))
	if box_count >= 5: _show_toast("Caja llena · llévala a la camioneta."); return
	if crop_id.is_empty(): crop_id = _available_produce()
	var amount: int = mini(5 - box_count, _loose_produce(crop_id))
	if amount <= 0: _show_toast("No tienes cosecha disponible para esta caja."); return
	box["crop_id"] = crop_id
	box["count"] = box_count + amount
	produce_boxes[index] = box
	_show_toast("%s · caja %d/5" % [CropDB.by_id(crop_id).name, int(box.count)])
	_refresh_hud()

func _near_world_point(point: Vector2, distance: float) -> bool:
	return player_pos.distance_to(point) < distance

func _can_use_land(tile: Vector2i) -> bool:
	if _is_path(tile): return false
	if tile.x >= 17 and tile.x <= 28 and tile.y >= 14 and tile.y <= 26: return true
	return owned_parcels >= 2 and tile.x >= 29 and tile.x <= 39 and tile.y >= 14 and tile.y <= 26

func _sleep() -> void:
	if sleeping: return
	if location != "farm" or truck_driving:
		_show_toast("Vuelve a la granja y baja de la camioneta para dormir."); return
	confirmation_back = ""
	_open_modal("confirm_sleep")

func _begin_sleep() -> void:
	_close_modal()
	sleeping = true
	sleep_transition_time = 0.0
	sleep_day_advanced = false
	move_vector = Vector2.ZERO
	player_animation = "idle"
	tool_charge = 0.0
	_refresh_hud()

func _finish_sleep_day() -> void:
	sleep_day_advanced = true
	_advance_day()
	energy = 100.0
	minute = 360.0
	water = max_water
	if Saves.save_game(_pack_state()): _show_toast("Nuevo día · partida guardada")
	else: _show_toast("Nuevo día · no se pudo guardar")
	_refresh_hud()

func _key_tile(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))

func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

func _show_toast(message: String) -> void:
	toast = message; toast_time = 2.8
	if is_instance_valid(toast_label): toast_label.text = message; toast_label.visible = true

func _action(name: String) -> void:
	player_animation = name; action_time = 0.36
	if haptics and last_input_was_gamepad:
		var pads := Input.get_connected_joypads()
		if not pads.is_empty(): Input.start_joy_vibration(pads[0], 0.12, 0.22, 0.06)
	var tint: Color = Color("c99462")
	match name:
		"water": tint = Color("9dd9df")
		"harvest": tint = Color("f2d17c")
		"chop": tint = Color("c98a58")
		"mine": tint = Color("b8c3bf")
		"plant": tint = Color("7fae5a")
	for i: int in range(7):
		var angle: float = randf_range(-PI*0.86, -PI*0.14)
		var velocity := Vector2(cos(angle),sin(angle))*randf_range(16.0,44.0)
		particles.append({"pos":_target_tile_center()+Vector2(randf_range(-5,5),randf_range(-5,5)),"vel":velocity,"life":randf_range(0.22,0.48),"color":tint})
	var sound_id: String = ""
	match name:
		"dig", "plant": sound_id = "soil"
		"water": sound_id = "water"
		"harvest": sound_id = "harvest"
		"chop": sound_id = "wood"
		"mine": sound_id = "stone"
	if not sound_id.is_empty() and is_instance_valid(sfx_player):
		sfx_player.stream = SFX[sound_id]
		sfx_player.play()

func _build_hud() -> void:
	canvas = CanvasLayer.new(); canvas.layer = 5; add_child(canvas)
	hud = Control.new(); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); canvas.add_child(hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 20
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.95, 0.83, 0.48, 0.12)
	focus.border_color = Color("ffe59a"); focus.set_border_width_all(3); focus.set_corner_radius_all(10)
	theme.set_stylebox("focus", "Button", focus)
	hud.theme = theme
	var top := PanelContainer.new(); top.position = Vector2(20, 16); top.size = Vector2(520, 88); hud.add_child(top); top.add_theme_stylebox_override("panel", _panel_style(Color("293c32"), 0.97, 14))
	var info := VBoxContainer.new(); top.add_child(info)
	day_label = Label.new(); day_label.add_theme_font_size_override("font_size", 24); info.add_child(day_label)
	money_label = Label.new(); money_label.add_theme_color_override("font_color", Color("f6d277")); info.add_child(money_label)
	var status := PanelContainer.new(); status.set_anchors_preset(Control.PRESET_TOP_RIGHT); status.position = Vector2(-280, 16); status.size = Vector2(260, 100); hud.add_child(status); status.add_theme_stylebox_override("panel", _panel_style(Color("293c32"), 0.97, 14))
	var status_box := VBoxContainer.new(); status.add_child(status_box)
	energy_bar = ProgressBar.new(); energy_bar.custom_minimum_size = Vector2(220, 26); energy_bar.max_value = 100; energy_bar.show_percentage = true; energy_bar.add_theme_stylebox_override("fill", _panel_style(Color("87af5e"), 1.0, 6)); energy_bar.add_theme_stylebox_override("background", _panel_style(Color("17251e"), 1.0, 6)); status_box.add_child(energy_bar)
	water_label = Label.new(); water_label.add_theme_color_override("font_color", Color("aee3db")); status_box.add_child(water_label)
	objective_label = Label.new(); objective_label.position = Vector2(24, 118); objective_label.size = Vector2(600, 70); objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; objective_label.add_theme_font_size_override("font_size", 20); objective_label.add_theme_color_override("font_color", Color("fff1d4")); objective_label.add_theme_stylebox_override("normal", _panel_style(Color("21332a"), 0.94, 10)); hud.add_child(objective_label)
	var context := PanelContainer.new(); context.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); context.offset_left = 20; context.offset_right = -20; context.offset_top = -210; context.offset_bottom = -100; hud.add_child(context); context.add_theme_stylebox_override("panel", _panel_style(Color("21332a"), 0.98, 14))
	var context_col := VBoxContainer.new(); context_col.add_theme_constant_override("separation", 2); context.add_child(context_col)
	action_label = Label.new(); action_label.add_theme_font_size_override("font_size", 25); action_label.add_theme_color_override("font_color", Color("ffe59a")); context_col.add_child(action_label)
	tool_label = Label.new(); tool_label.add_theme_font_size_override("font_size", 20); context_col.add_child(tool_label)
	hint_label = Label.new(); hint_label.add_theme_font_size_override("font_size", 18); hint_label.add_theme_color_override("font_color", Color("c1d4bd")); context_col.add_child(hint_label)
	var hotbar := PanelContainer.new(); hotbar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); hotbar.offset_left = 20; hotbar.offset_right = 884; hotbar.offset_top = -88; hotbar.offset_bottom = -16; hud.add_child(hotbar); hotbar.add_theme_stylebox_override("panel", _panel_style(Color("293c32"), 0.98, 14))
	var slots := HBoxContainer.new(); slots.add_theme_constant_override("separation", 8); hotbar.add_child(slots)
	for i: int in range(6):
		var button := Button.new(); button.custom_minimum_size = Vector2(126, 52); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.text = tool_names[i]; button.focus_mode = Control.FOCUS_NONE; button.toggle_mode = true; button.add_theme_font_size_override("font_size", 20); button.pressed.connect(_select_tool.bind(i)); slots.add_child(button); tool_buttons.append(button)
	seed_picker_button = Button.new(); seed_picker_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); seed_picker_button.offset_left = -376; seed_picker_button.offset_right = -20; seed_picker_button.offset_top = -88; seed_picker_button.offset_bottom = -16; seed_picker_button.focus_mode = Control.FOCUS_NONE; seed_picker_button.pressed.connect(_open_seed_selector); hud.add_child(seed_picker_button)
	deposit_produce_button = Button.new(); deposit_produce_button.visible = false; deposit_produce_button.focus_mode = Control.FOCUS_NONE; hud.add_child(deposit_produce_button)
	toast_label = Label.new(); toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP); toast_label.offset_left = -480; toast_label.offset_right = 480; toast_label.offset_top = 202; toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; toast_label.add_theme_font_size_override("font_size", 22); toast_label.add_theme_color_override("font_color", Color("fff1ce")); toast_label.add_theme_stylebox_override("normal", _panel_style(Color("21332a"), 0.97, 10)); toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(toast_label); toast_label.visible = false
	travel_button = Button.new(); travel_button.position = Vector2(560, 16); travel_button.custom_minimum_size = Vector2(410, 60); travel_button.focus_mode = Control.FOCUS_NONE; travel_button.pressed.connect(_open_modal.bind("travel")); hud.add_child(travel_button)
	modal_shade = ColorRect.new(); modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_shade.color = Color(0.04, 0.09, 0.07, 0.8); modal_shade.visible = false; hud.add_child(modal_shade)
	modal_panel = PanelContainer.new(); modal_panel.set_anchors_preset(Control.PRESET_CENTER); modal_panel.position = Vector2(-520, -352); modal_panel.size = Vector2(1040, 704); modal_panel.visible = false; hud.add_child(modal_panel); modal_panel.add_theme_stylebox_override("panel", _panel_style(Color("293c32"), 0.99, 18))
	var modal_col := VBoxContainer.new(); modal_col.add_theme_constant_override("separation", 12); modal_panel.add_child(modal_col)
	var title_row := HBoxContainer.new(); modal_col.add_child(title_row)
	modal_title = Label.new(); modal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; modal_title.add_theme_font_size_override("font_size", 30); modal_title.add_theme_color_override("font_color", Color("f6e3b7")); title_row.add_child(modal_title)
	var close := Button.new(); close.text = "Volver"; close.custom_minimum_size = Vector2(150, 52); close.pressed.connect(_back_from_modal); title_row.add_child(close); modal_close_button = close
	modal_scroll = ScrollContainer.new(); modal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; modal_scroll.follow_focus = true; modal_col.add_child(modal_scroll)
	modal_body = VBoxContainer.new(); modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; modal_body.add_theme_constant_override("separation", 10); modal_scroll.add_child(modal_body)
	modal_footer = Label.new(); modal_footer.add_theme_font_size_override("font_size", 18); modal_footer.add_theme_color_override("font_color", Color("c1d4bd")); modal_col.add_child(modal_footer)
	_refresh_hud()

func _panel_style(color: Color, alpha: float, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(color, alpha); style.set_corner_radius_all(radius); style.set_border_width_all(2); style.border_color = Color("a6b17b", 0.42); style.content_margin_left = 14; style.content_margin_right = 14; style.content_margin_top = 10; style.content_margin_bottom = 10; return style

func _refresh_hud() -> void:
	if not is_instance_valid(day_label): return
	for child: Node in hud.get_children():
		if child is CanvasItem and child not in [modal_panel, modal_shade, toast_label]: child.visible = not at_title
	modal_close_button.text = "B  Volver" if last_input_was_gamepad else "Esc  Volver"
	modal_footer.text = "Cruceta / stick: navegar    A: elegir    B: volver" if last_input_was_gamepad else "Flechas: navegar    Intro: elegir    Esc: volver"
	if modal == "shop": modal_footer.text += "    ·    L1/R1: página" if last_input_was_gamepad else "    ·    R/Q: página"
	deposit_produce_button.visible = false
	if at_title:
		toast_label.visible = false
		return
	travel_button.text = "%s · %s Viajar" % [Places.NAMES[location], "↓" if last_input_was_gamepad else "T"]
	day_label.text = "%s · Día %02d · %s" % [SEASONS[season_index], day, _clock_text()]
	money_label.text = "%d monedas · %s" % [coins, weather]
	energy_bar.value = energy
	water_label.text = "Agua %d/%d · Energía" % [water, max_water]
	var seed: Dictionary = CropDB.by_id(selected_seed_id)
	seed_picker_button.text = "%s %s ×%d" % ["↑" if last_input_was_gamepad else "Z", seed.get("name", "Semillas"), int(inventory.get(selected_seed_id + "_seed", 0))]
	seed_picker_button.visible = location == "farm" and not truck_driving
	for index: int in range(tool_buttons.size()):
		tool_buttons[index].set_pressed_no_signal(index == selected_tool)
		tool_buttons[index].modulate = Color("ffe59a") if index == selected_tool else Color.WHITE
	var target := _primary_target()
	var primary: String = "A" if last_input_was_gamepad else "E"
	var secondary: String = "X" if last_input_was_gamepad else "Espacio"
	action_label.text = "%s  %s" % [primary, target.get("label", "Apunta a una casilla o acércate a un objeto")]
	if truck_driving:
		action_label.text += "    ·    %s  Aparcar y bajar" % secondary
		tool_label.text = "Camioneta · %d/%d cajas · %d monedas en carga" % [truck_cargo.size(), TRUCK_CAPACITY, _cargo_value()]
	elif moving_box_index >= 0:
		tool_label.text = "Llevas una caja · orienta con el stick derecho · B para soltar" if last_input_was_gamepad else "Llevas una caja · orienta con WASD · E para soltar"
	else:
		tool_label.text = "%s  %s · %s · %s" % [secondary, "Cargar cosecha" if _can_quick_load() else tool_names[selected_tool], "L1/R1 herramientas" if last_input_was_gamepad else "R/Q herramientas", "Y mochila" if last_input_was_gamepad else "I mochila"]
		if tool_names[selected_tool] in ["Azada", "Regadera"] and int(tool_levels.get(tool_names[selected_tool], 1)) >= 2:
			tool_label.text += " · %s: cargar 3×3" % ("R2" if last_input_was_gamepad else "Mayús")
	hint_label.text = "Stick izq: mover · dcho: apuntar · ↑ semillas · ↓ viajar · Menú: pausa" if last_input_was_gamepad else "WASD: mover · ratón: apuntar · Z: semillas · T: viajar · Esc: pausa"
	if tool_charge > 0.0: hint_label.text = "Carga %d%% · suelta para usar · 3×3 desde nivel 2" % mini(100, roundi(tool_charge / 0.55 * 100.0))
	objective_label.text = _next_objective()

func _cargo_value() -> int:
	var value: int = 0
	for box: Dictionary in truck_cargo: value += int(box.get("value", 0))
	return value

func _next_objective() -> String:
	if truck_driving: return "Lleva la carga al puesto y pulsa %s para vender." % ("A" if last_input_was_gamepad else "E")
	if location != "farm": return "Explora %s · ↓ / T abre los viajes." % Places.NAMES[location]
	if energy < 15.0: return "Energía baja · descansa quieto o duerme en casa."
	if water == 0: return "Regadera vacía · llénala en el pozo."
	if not _available_produce().is_empty(): return "Cosecha en la mochila · acércate a la camioneta y pulsa %s para cargar." % ("X" if last_input_was_gamepad else "Espacio")
	for plot: Dictionary in plots.values():
		if not String(plot.get("crop_id", "")).is_empty() and not bool(plot.get("watered", false)) and not bool(plot.get("wilted", false)):
			return "Cuida tus cultivos · apunta y usa la acción principal para regar."
	if plots.is_empty(): return "Empieza aquí · apunta dentro de la parcela y pulsa %s para despejar." % ("A" if last_input_was_gamepad else "E")
	return "Despeja → prepara → siembra → riega. Mantén la acción para trabajar en fila."

func _clock_text() -> String:
	var h: int = int(minute / 60.0); var m: int = int(minute) % 60
	return "%02d:%02d" % [h, m]

func _select_tool(index: int) -> void:
	tool_charge = 0.0
	selected_tool = index; _refresh_hud()

func _open_modal(which: String) -> void:
	if sleeping: return
	var old_modal: String = modal
	var focused: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focused_path: NodePath = modal_body.get_path_to(focused) if focused != null and modal_body.is_ancestor_of(focused) else NodePath("")
	var scroll_position: int = modal_scroll.scroll_vertical
	tool_charge = 0.0
	repeat_elapsed = 0.0
	modal = which; modal_panel.visible = true
	modal_shade.visible = true
	modal_close_button.visible = not at_title
	for child: Node in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	match which:
		"title": _populate_title()
		"settings": _populate_settings()
		"controls": _populate_controls()
		"travel": _populate_travel()
		"confirm_sleep": _populate_confirmation("¿Irte a dormir?", "Terminarás el día. Recuperarás energía y se guardará la partida al amanecer.", _begin_sleep)
		"shop": _populate_shop()
		"workshop": _populate_workshop()
		"inventory": _populate_inventory()
		"seeds": _populate_seeds()
		"land": _populate_land()
		"pause": _populate_pause()
		"confirm_new": _populate_confirmation("¿Empezar una nueva partida?", "Se reiniciará la granja y se sustituirá el guardado actual.", _start_new_game)
		"confirm_load": _populate_confirmation("¿Cargar la partida guardada?", "Se perderán los cambios que no hayas guardado.", _load_saved_game)
	var first: Control = _first_focusable(modal_body)
	if old_modal == which and not focused_path.is_empty():
		var same := modal_body.get_node_or_null(focused_path) as Button
		if same != null and not same.disabled: first = same
	else: modal_scroll.scroll_vertical = 0
	if first != null and is_inside_tree(): first.grab_focus()
	if old_modal == which: modal_scroll.set_deferred("scroll_vertical", scroll_position)
	_refresh_hud()

func _first_focusable(node: Node) -> Control:
	if node is Control and (node as Control).focus_mode != Control.FOCUS_NONE and not (node is BaseButton and node.disabled):
		return node as Control
	for child: Node in node.get_children():
		var found: Control = _first_focusable(child)
		if found != null: return found
	return null

func _close_modal() -> void:
	if at_title:
		_open_modal("title"); return
	modal = ""; modal_panel.visible = false
	modal_shade.visible = false
	if is_inside_tree(): get_viewport().gui_release_focus()

func _crop_icon(crop: Dictionary, kind: String = "product") -> Texture2D:
	var path: String = String(crop.get(kind + "_sprite", ""))
	if path.is_empty(): return null
	var key: String = path + ":" + str(crop.sprite_index)
	if not crop_icon_cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(path) as Texture2D
		var index: int = int(crop.sprite_index)
		atlas.region = Rect2((index % 6) * 64, (index / 6) * 64, 64, 64)
		crop_icon_cache[key] = atlas
	return crop_icon_cache[key]

func _add_crop_icon(row: HBoxContainer, crop: Dictionary, kind: String) -> void:
	var icon := TextureRect.new()
	icon.texture = _crop_icon(crop, kind)
	icon.custom_minimum_size = Vector2(44,44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

func _crop_schedule(crop: Dictionary) -> String:
	return "%d días · %d/cosecha · %s" % [crop.days, int(crop.get("yield", 2)), "rebrota en %d días" % crop.repeat if int(crop.repeat) > 0 else "cosecha única"]

func _choose_shop_season(index: int) -> void:
	shop_page = 0
	shop_season = index
	_open_modal("shop")

func _change_shop_page(direction: int) -> void:
	shop_page = posmod(shop_page + direction, 6)
	_open_modal("shop")
	modal_scroll.scroll_vertical = 0

func _populate_shop() -> void:
	modal_title.text = "Tienda · %d monedas" % coins
	var tabs := HBoxContainer.new(); modal_body.add_child(tabs)
	var active: int = season_index if shop_season < 0 else shop_season
	for index: int in range(4):
		var tab := Button.new(); tab.text = ("✓ " if active == index else "") + SEASONS[index]; tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tab.custom_minimum_size.y = 52; tab.pressed.connect(_choose_shop_season.bind(index)); tabs.add_child(tab)
	var navigation := HBoxContainer.new(); modal_body.add_child(navigation)
	var prev := Button.new(); prev.text = "‹ Anterior"; prev.custom_minimum_size = Vector2(180, 48); prev.pressed.connect(_change_shop_page.bind(-1)); navigation.add_child(prev)
	var page := Label.new(); page.text = "Página %d/6 · bolsas de 5 semillas" % (shop_page + 1); page.size_flags_horizontal = Control.SIZE_EXPAND_FILL; page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; navigation.add_child(page)
	var next := Button.new(); next.text = "Siguiente ›"; next.custom_minimum_size = Vector2(180, 48); next.pressed.connect(_change_shop_page.bind(1)); navigation.add_child(next)
	var crops: Array[Dictionary] = CropDB.crops_for_season(SEASONS[active])
	for crop: Dictionary in crops.slice(shop_page * SHOP_PAGE_SIZE, (shop_page + 1) * SHOP_PAGE_SIZE):
		var row := HBoxContainer.new(); row.custom_minimum_size.y = 76; row.add_theme_constant_override("separation", 12); modal_body.add_child(row)
		_add_crop_icon(row, crop, "product")
		var text := Label.new(); text.text = "%s · tienes %d semillas\n%s · venta %d/u." % [crop.name, int(inventory.get(String(crop.id) + "_seed", 0)), _crop_schedule(crop), crop.sell]; text.size_flags_horizontal = Control.SIZE_EXPAND_FILL; text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; row.add_child(text)
		var buy := Button.new(); buy.text = "Comprar %s\n×5 · %d monedas" % [crop.name, crop.seed]; buy.custom_minimum_size = Vector2(250, 64); buy.disabled = coins < int(crop.seed); buy.pressed.connect(_buy_seed.bind(String(crop.id))); row.add_child(buy)
	_menu_button("Vender toda la cosecha de la mochila", _sell_all_produce, _available_produce().is_empty())
	_menu_button("Taller · elegir herramienta y mejorar", _open_modal.bind("workshop"))

func _populate_workshop() -> void:
	modal_title.text = "Taller · %d monedas" % coins
	_add_note("Cada mejora cuesta 80 monedas, 3 de madera y 2 de piedra. Azada y regadera de nivel 2: mantén R2 / Mayús para trabajar 3×3.")
	for index: int in [0, 1, 3, 4, 5]:
		var name: String = tool_names[index]
		var eligible: bool = int(tool_levels[name]) < 6 and coins >= 80 and int(inventory.get("wood", 0)) >= 3 and int(inventory.get("stone", 0)) >= 2
		_menu_button("%s · nivel %d · mejorar" % [name, int(tool_levels[name])], _upgrade_chosen_tool.bind(index), not eligible)

func _upgrade_chosen_tool(index: int) -> void:
	selected_tool = index
	_upgrade_tool()
	_open_modal("workshop")

func _sell_all_produce() -> void:
	var total: int = 0
	for crop_id: String in _produce_ids():
		var crop: Dictionary = CropDB.by_id(crop_id)
		var amount: int = _loose_produce(crop_id)
		if amount > 0:
			total += _take_box_stock_value(String(crop.id), amount, int(crop.sell))
			xp.Comercio += amount * 3
	coins += total
	_show_toast("Cosecha vendida · +%d monedas" % total)
	_open_modal("shop")

func _seed_catalog() -> Array[Dictionary]:
	var crops: Array[Dictionary] = CropDB.all_crops()
	for item: Variant in inventory.keys():
		var key: String = String(item)
		if key.begins_with("catalog_") and key.ends_with("_seed"):
			var legacy: Dictionary = CropDB.by_id(key.trim_suffix("_seed"))
			if not legacy.is_empty(): crops.append(legacy)
	return crops

func _open_seed_selector() -> void:
	if location != "farm": return
	selected_tool = tool_names.find("Semillas")
	_refresh_hud()
	_open_modal("seeds")

func _populate_seeds() -> void:
	modal_title.text = "Elige qué sembrar"
	_add_note("Solo aparecen semillas que tienes en la mochila.")
	var available: int = 0
	for crop: Dictionary in _seed_catalog():
		var crop_id: String = String(crop.id)
		var amount: int = int(inventory.get(crop_id + "_seed", 0))
		if amount <= 0: continue
		available += 1
		var button := Button.new()
		var marker: String = "✓  " if crop_id == selected_seed_id else "    "
		button.text = "%s%s   ·   ×%d   ·   %s" % [marker, String(crop.name), amount, String(crop.season)]
		button.icon = _crop_icon(crop, "seed")
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 40)
		button.tooltip_text = _crop_schedule(crop)
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_select_seed.bind(crop_id))
		modal_body.add_child(button)
	if available == 0:
		_add_note("No te quedan semillas. Compra algunas en el mercadillo.")
		var shop_button := Button.new()
		shop_button.text = "Ir al mercadillo"
		shop_button.custom_minimum_size = Vector2(0, 52)
		shop_button.focus_mode = Control.FOCUS_ALL
		shop_button.pressed.connect(_open_modal.bind("shop"))
		modal_body.add_child(shop_button)

func _select_seed(crop_id: String) -> void:
	var crop: Dictionary = CropDB.by_id(crop_id)
	var amount: int = int(inventory.get(crop_id + "_seed", 0))
	if crop.is_empty() or amount <= 0:
		_show_toast("Ya no tienes semillas de esa variedad.")
		_open_modal("seeds")
		return
	selected_seed_id = crop_id
	selected_tool = tool_names.find("Semillas")
	_close_modal()
	_show_toast("Semilla seleccionada: %s ×%d" % [String(crop.name), amount])
	_refresh_hud()

func _populate_inventory() -> void:
	modal_title.text = "Mochila"
	_add_note("La cosecha se acumula aquí. X / Espacio junto a la camioneta carga hasta 6 cajas, de 1 a 5 productos cada una. También puedes vender la cosecha suelta en la tienda.")
	var keys: Array = inventory.keys(); keys.sort()
	for item: Variant in keys:
		var amount: int = int(inventory[item]); if amount <= 0: continue
		var row := HBoxContainer.new(); row.custom_minimum_size = Vector2(0, 44); modal_body.add_child(row)
		var item_id: String = String(item)
		var is_seed: bool = item_id.ends_with("_seed")
		var item_crop: Dictionary = CropDB.by_id(item_id.trim_suffix("_seed") if is_seed else item_id)
		if not item_crop.is_empty(): _add_crop_icon(row, item_crop, "seed" if is_seed else "product")
		var item_name: String = String(item_crop.name) + (" · semillas" if is_seed else "") if not item_crop.is_empty() else item_id.replace("_", " ")
		var label := Label.new(); label.text = item_name; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; label.add_theme_font_size_override("font_size", 20); row.add_child(label)
		var count := Label.new(); count.text = "× %d" % amount; count.custom_minimum_size = Vector2(72, 40); count.add_theme_font_size_override("font_size", 20); count.add_theme_color_override("font_color", Color("f6d277")); row.add_child(count)
		if quality_stock.has(String(item)):
			var quality_label := Label.new(); quality_label.text = _quality_summary(quality_stock[String(item)]); quality_label.custom_minimum_size = Vector2(170, 40); quality_label.add_theme_font_size_override("font_size", 18); quality_label.add_theme_color_override("font_color", Color("d1dda5")); row.add_child(quality_label)
	for key: Variant in plots.keys():
		var plot: Dictionary = plots[key]; if String(plot.get("crop_id", "")).is_empty(): continue
		var crop: Dictionary = CropDB.by_id(String(plot.crop_id)); if crop.is_empty(): continue
		_add_note("Parcela %s: %s · día %d/%d · %s" % [String(key), crop.name, int(plot.growth), int(crop.days), "marchita" if plot.wilted else ("regada" if plot.watered else "necesita agua")])
	var stats := Button.new(); stats.text = "Habilidades  ·  Cultivo %d  Tala %d  Minería %d" % [int(xp.Agricultura / 100) + 1, int(xp.Tala / 100) + 1, int(xp.Minería / 100) + 1]; stats.custom_minimum_size = Vector2(0, 46); modal_body.add_child(stats)

func _populate_land() -> void:
	modal_title.text = "La parcela del arroyo"
	_add_note("Un rincón fértil junto al agua, con bosque y piedras para aprovechar.")
	_add_note("Extensión: 11 × 13 casillas · precio: 450 ◈")
	var buy := Button.new(); buy.text = "Comprar terreno · 450 ◈"; buy.custom_minimum_size = Vector2(0, 58); buy.pressed.connect(_buy_land); modal_body.add_child(buy)
	_add_note("Al ampliar la granja también aparecerán árboles, maleza y recursos nuevos.")

func _populate_pause() -> void:
	confirmation_back = "pause"
	modal_title.text = "Pausa · %s" % Places.NAMES[location]
	_menu_button("Continuar jugando", _close_modal)
	_menu_button("Mochila", _open_modal.bind("inventory"))
	_menu_button("Viajar al río, pueblo o granja", _open_modal.bind("travel"))
	_menu_button("Dormir y guardar", func() -> void: _close_modal(); _sleep(), location != "farm" or truck_driving)
	_menu_button("Ajustes de juego y cámara", _show_settings)
	_menu_button("Ver todos los controles", _show_controls)
	_menu_button("Guardar partida", _save_now)
	_menu_button("Cargar partida…", _open_modal.bind("confirm_load"))
	_menu_button("Nueva partida…", _open_modal.bind("confirm_new"))
	_menu_button("Volver al inicio…", _return_to_title)
	_menu_button("Salir del juego", _exit_game)

func _show_settings() -> void:
	settings_back = "title" if at_title else "pause"
	_open_modal("settings")

func _show_controls() -> void:
	settings_back = "title" if at_title else "pause"
	_open_modal("controls")

func _populate_settings() -> void:
	modal_title.text = "A tu ritmo"
	_add_note("Los ajustes se incluyen al guardar tu partida. Todos se pueden cambiar con mando.")
	_menu_button("Acción contextual: %s" % ("activada" if assisted_actions else "manual"), _toggle_setting.bind("assisted_actions"))
	_menu_button("Mantener botón para repetir: %s" % ("sí" if repeat_actions else "no"), _toggle_setting.bind("repeat_actions"))
	_menu_button("Ritmo del día: %s" % ("tranquilo · 6 minutos reales" if relaxed_clock else "ágil · 3 minutos reales"), _toggle_setting.bind("relaxed_clock"))
	_menu_button("Vibración: %s" % ("sí" if haptics else "no"), _toggle_setting.bind("haptics"))
	_menu_button("Acercar cámara · %.0f%%" % (camera_zoom * 100.0), _settings_zoom.bind(0.1))
	_menu_button("Alejar cámara · %.0f%%" % (camera_zoom * 100.0), _settings_zoom.bind(-0.1))
	_menu_button("Restablecer cámara · 135%", _settings_zoom.bind(0.0))

func _toggle_setting(key: String) -> void:
	set(key, not bool(get(key)))
	_open_modal("settings")

func _settings_zoom(amount: float) -> void:
	_set_zoom(1.35 if amount == 0.0 else camera_zoom + amount)
	_open_modal("settings")

func _populate_controls() -> void:
	modal_title.text = "Controles · Steam Deck"
	_add_note("Stick izquierdo: mover. Stick derecho: apuntar; al volver a caminar, apuntas hacia donde avanzas.")
	_add_note("A / E: acción contextual. Despeja, prepara, siembra, riega y cosecha según la casilla. Junto a objetos: interactúa.")
	_add_note("X / Espacio: herramienta seleccionada. Junto a la camioneta: carga rápida. Al conducir: aparca y baja.")
	_add_note("L1/R1 · R/Q: cambiar herramienta. Mantén X para repetir. R2 / Mayús: mantener y soltar para cargar azada o regadera de nivel 2 (3×3).")
	_add_note("Y / I: mochila. Cruceta ↑ / Z: elegir semillas. ←/→ / V/C: cambiar variedad. Cruceta ↓ / T: viajar.")
	_add_note("B / Esc: volver o pausar. Con una caja: soltar. Menú / Start: pausa. En menús: cruceta o stick para navegar, A / Intro elige, B vuelve.")
	_add_note("Cosecha sin volver a las cajas: se acumula en la mochila. X junto a la camioneta empaqueta y carga; A en el mercado vende la carga.")
	_add_note("Ratón: clic para herramienta, rueda para zoom, botón derecho para mover cajas. También puedes ajustar la cámara en Pausa → Ajustes.")

func _populate_confirmation(title: String, description: String, confirm_action: Callable) -> void:
	modal_title.text = title
	_add_note(description)
	_menu_button("Cancelar · seguir como estaba", _cancel_confirmation)
	_menu_button("Confirmar", confirm_action)

func _exit_game() -> void:
	get_tree().quit()

func _add_note(text: String) -> void:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_size_override("font_size", 20); label.add_theme_color_override("font_color", Color("e6e2c8")); label.custom_minimum_size = Vector2(0, 32); modal_body.add_child(label)

func _quality_summary(tiers: Dictionary) -> String:
	var parts: PackedStringArray = []
	for tier: String in ["excepcional", "excelente", "buena", "normal"]:
		var amount: int = int(tiers.get(tier, 0))
		if amount > 0: parts.append("%s %d" % [tier.capitalize(), amount])
	return "  ·  ".join(parts)

func _buy_seed(crop_id: String) -> void:
	var crop: Dictionary = CropDB.by_id(crop_id); if crop.is_empty(): return
	var transaction: Dictionary = Economy.buy(coins, int(crop.seed), 1)
	if not transaction.ok: _show_toast("Te faltan monedas."); return
	coins = int(transaction.balance); var key := crop_id + "_seed"; inventory[key] = int(inventory.get(key, 0)) + int(crop.get("seed_pack", 5)); selected_seed_id = crop_id
	_show_toast("Semillas de %s ×5" % crop.name); _open_modal("shop"); _refresh_hud()

func _sell_crop(crop_id: String) -> void:
	var crop: Dictionary = CropDB.by_id(crop_id); var amount: int = int(inventory.get(crop_id, 0))
	if amount <= 0: _show_toast("No tienes %s para vender." % crop.name); return
	var transaction: Dictionary = Economy.sell(coins, int(crop.sell), amount, amount)
	var tiers: Dictionary = quality_stock.get(crop_id, {"normal": amount})
	var earning: int = 0
	for tier: Variant in tiers.keys():
		var multiplier: float = 1.0
		match String(tier):
			"buena": multiplier = 1.25
			"excelente": multiplier = 1.6
			"excepcional": multiplier = 2.25
		earning += roundi(float(crop.sell) * multiplier * int(tiers[tier]))
	coins += earning; inventory[crop_id] = amount - int(transaction.quantity); quality_stock.erase(crop_id); xp.Comercio += amount * 3
	for index: int in range(produce_boxes.size()):
		if String(produce_boxes[index].get("crop_id", "")) == crop_id:
			produce_boxes[index] = {"crop_id":"", "count":0}
	_show_toast("Vendiste %s ×%d · +%d ◈" % [crop.name, amount, earning]); _open_modal("shop"); _refresh_hud()

func _upgrade_tool() -> void:
	var name: String = tool_names[selected_tool]
	if not tool_levels.has(name):
		_show_toast("Elige una herramienta; las semillas no se mejoran."); return
	var transaction: Dictionary = Economy.upgrade(int(tool_levels[name]), coins, int(inventory.get("wood", 0)), int(inventory.get("stone", 0)))
	if not transaction.ok: _show_toast("Mejora: 80 monedas, 3 maderas y 2 piedras; herramienta bajo nivel 6."); return
	coins = int(transaction.balance); inventory.wood = int(transaction.wood); inventory.stone = int(transaction.stone); tool_levels[name] = int(transaction.level)
	if name == "Regadera": max_water += 4; water = max_water
	_show_toast("¡%s mejorada al nivel %d!" % [name, tool_levels[name]]); _open_modal("shop"); _refresh_hud()

func _buy_land() -> void:
	if owned_parcels >= 2: _show_toast("Ya tienes esta parcela."); return
	if coins < 450: _show_toast("Aún necesitas %d monedas." % (450 - coins)); return
	coins -= 450; owned_parcels = 2
	var rng := RandomNumberGenerator.new(); rng.seed = 205
	var obstacles := _layout_obstacles()
	for y: int in range(15, 26):
		for x: int in range(30, 40):
			if rng.randf() < 0.13:
				var candidate := {"tile":Vector2i(x,y),"kind":"tree" if rng.randf() < 0.5 else "rock","hp":3,"variant":rng.randi_range(0,3)}
				if _can_place_prop(candidate, obstacles): props.append(candidate)
	for prop: Dictionary in props:
		Fruit.initialize(prop, fruit_rng)
	_repair_prop_layout()
	_show_toast("¡El terreno del arroyo es tuyo!"); _close_modal(); _refresh_hud()

func _save_now() -> void:
	if Saves.save_game(_pack_state()): _show_toast("Partida guardada")
	else: _show_toast("No se pudo guardar")

func _load_saved_game() -> void:
	var data: Dictionary = Saves.load_game()
	if data.is_empty():
		_show_toast("No hay ninguna partida guardada.")
		_open_modal("title" if at_title else "pause")
		return
	at_title = false
	_close_modal()
	sleeping = false
	_load_state(data)
	_refresh_hud()
	_show_toast("Partida cargada")

func _start_new_game() -> void:
	action_cooldown = 0.0
	repeat_kind = ""
	repeat_tile = Vector2i(-1,-1)
	shop_season = -1
	shop_page = 0
	road_exit_cooldown = 0.0
	at_title = false
	location = "farm"
	truck_location = "farm"
	_close_modal()
	player_pos = Vector2(704,560)
	facing = Vector2.RIGHT
	walk_phase = 0.0
	camera_zoom = 1.35
	aim_stick = Vector2.ZERO
	mouse_aim_active = false
	mouse_target_tile = Vector2i.ZERO
	selected_tool = 0
	selected_seed_id = "turnip"
	tool_levels = {"Azada":1, "Regadera":1, "Hacha":1, "Pico":1, "Guadaña":1}
	inventory = {"turnip_seed":5, "carrot_seed":4, "potato_seed":3, "wood":0, "stone":0}
	quality_stock.clear()
	plots.clear()
	coins = 180
	energy = 100.0
	water = 12
	max_water = 12
	day = 1
	season_index = 0
	minute = 360.0
	weather = "Soleado"
	rain_today = false
	owned_parcels = 1
	xp = {"Agricultura":0, "Tala":0, "Minería":0, "Recolección":0, "Comercio":0}
	carried_crop_id = ""
	carried_crop_count = 0
	carried_quality = "normal"
	truck_pos = Vector2(1152, 624)
	truck_facing = Vector2.LEFT
	truck_driving = false
	truck_cargo.clear()
	produce_box_tiles = [Vector2i(29,17), Vector2i(29,18), Vector2i(29,19)]
	moving_box_index = -1
	mouse_dragging_box = false
	produce_boxes.clear()
	for _index: int in range(produce_box_tiles.size()): produce_boxes.append({"crop_id":"", "count":0})
	sleeping = false
	sleep_transition_time = 0.0
	sleep_day_advanced = false
	action_time = 0.0
	tool_charge = 0.0
	_make_world()
	_refresh_hud()
	if Saves.save_game(_pack_state()): _show_toast("Nueva partida · guardada")
	else: _show_toast("Nueva partida iniciada · no se pudo guardar")

func _pack_state() -> Dictionary:
	var prop_data: Array[Dictionary] = []
	for prop: Dictionary in props:
		var item := prop.duplicate(true); item.tile = [prop.tile.x, prop.tile.y]; prop_data.append(item)
	var box_tiles_data: Array = []
	for tile: Vector2i in produce_box_tiles: box_tiles_data.append([tile.x, tile.y])
	var saved_truck_pos: Vector2 = player_pos if truck_driving else truck_pos
	return {"location":location,"truck_location":truck_location,"player":[player_pos.x,player_pos.y],"coins":coins,"energy":energy,"water":water,"max_water":max_water,"day":day,"season":season_index,"minute":minute,"weather":weather,"parcels":owned_parcels,"inventory":inventory,"quality_stock":quality_stock,"plots":plots,"props":prop_data,"levels":tool_levels,"xp":xp,"selected_seed":selected_seed_id,"zoom":camera_zoom,"carried_crop_id":carried_crop_id,"carried_crop_count":carried_crop_count,"carried_quality":carried_quality,"produce_boxes":produce_boxes,"produce_box_tiles":box_tiles_data,"truck_pos":[saved_truck_pos.x,saved_truck_pos.y],"truck_facing":[truck_facing.x,truck_facing.y],"truck_cargo":truck_cargo,"truck_driving":truck_driving,"assisted_actions":assisted_actions,"repeat_actions":repeat_actions,"relaxed_clock":relaxed_clock,"haptics":haptics,"selected_tool":selected_tool}

func _load_state(data: Dictionary) -> void:
	assisted_actions = bool(data.get("assisted_actions", true))
	repeat_actions = bool(data.get("repeat_actions", true))
	relaxed_clock = bool(data.get("relaxed_clock", true))
	haptics = bool(data.get("haptics", true))
	selected_tool = clampi(int(data.get("selected_tool", 0)), 0, 5)
	action_cooldown = 0.0
	aim_stick = Vector2.ZERO
	tool_charge = 0.0
	road_exit_cooldown = 0.0
	location = String(data.get("location", "farm"))
	truck_location = String(data.get("truck_location", "farm"))
	if not Places.NAMES.has(location): location = "farm"
	if not Places.NAMES.has(truck_location): truck_location = "farm"
	var player: Array = data.get("player", [704,560]); if player.size() >= 2: player_pos = Vector2(float(player[0]), float(player[1]))
	coins = int(data.get("coins", 180)); energy = float(data.get("energy", 100)); water = int(data.get("water", 12)); max_water = int(data.get("max_water", 12))
	day = int(data.get("day", 1)); season_index = posmod(int(data.get("season", 0)), 4); minute = float(data.get("minute", 360)); weather = String(data.get("weather", "Soleado")); owned_parcels = int(data.get("parcels", 1))
	inventory = data.get("inventory", inventory); quality_stock = data.get("quality_stock", {}); plots = data.get("plots", {}); tool_levels = data.get("levels", tool_levels); xp = data.get("xp", xp)
	selected_seed_id = String(data.get("selected_seed", selected_seed_id)); camera_zoom = clampf(float(data.get("zoom", camera_zoom)), 0.85, 2.2)
	carried_crop_id = String(data.get("carried_crop_id", "")); carried_crop_count = int(data.get("carried_crop_count", 0)); carried_quality = String(data.get("carried_quality", "normal"))
	_migrate_hand_produce()
	var saved_truck_pos: Array = data.get("truck_pos", [1152, 624])
	if saved_truck_pos.size() >= 2: truck_pos = Vector2(float(saved_truck_pos[0]), float(saved_truck_pos[1]))
	if is_equal_approx(truck_pos.x, 1056.0) and is_equal_approx(truck_pos.y, 592.0): truck_pos = Vector2(1152, 624)
	var saved_truck_facing: Array = data.get("truck_facing", [-1, 0])
	if saved_truck_facing.size() >= 2: truck_facing = Vector2(float(saved_truck_facing[0]), float(saved_truck_facing[1]))
	truck_cargo.clear()
	for saved_cargo: Dictionary in data.get("truck_cargo", []): truck_cargo.append(saved_cargo.duplicate(true))
	truck_driving = bool(data.get("truck_driving", false)) and truck_location == location
	produce_box_tiles = [Vector2i(29,17), Vector2i(29,18), Vector2i(29,19)]
	var saved_box_tiles: Array = data.get("produce_box_tiles", [])
	var loaded_box_tiles: Array[Vector2i] = []
	for saved_tile: Array in saved_box_tiles:
		if saved_tile.size() >= 2: loaded_box_tiles.append(Vector2i(int(saved_tile[0]), int(saved_tile[1])))
	var had_old_default_boxes: bool = loaded_box_tiles.size() >= 3 and loaded_box_tiles[0] == Vector2i(25,29) and loaded_box_tiles[1] == Vector2i(28,29) and loaded_box_tiles[2] == Vector2i(31,29)
	if not had_old_default_boxes and not loaded_box_tiles.is_empty(): produce_box_tiles = loaded_box_tiles
	moving_box_index = -1
	mouse_dragging_box = false
	produce_boxes.clear()
	var saved_boxes: Array = data.get("produce_boxes", [])
	for saved_box: Dictionary in saved_boxes: produce_boxes.append(saved_box.duplicate(true))
	while produce_boxes.size() < produce_box_tiles.size(): produce_boxes.append({"crop_id":"", "count":0})
	while produce_box_tiles.size() < 3: produce_box_tiles.append(Vector2i(25 + produce_box_tiles.size(), 17))
	props.clear()
	_repair_box_layout()
	for source: Dictionary in data.get("props", []):
		var prop := source.duplicate(true); var t: Array = prop.get("tile", [0,0]); prop.tile = Vector2i(int(t[0]), int(t[1]))
		Fruit.initialize(prop, fruit_rng)
		props.append(prop)
	_repair_prop_layout()

func _draw() -> void:
	var viewport := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport), Color("213b3a"), true)
	draw_set_transform(viewport * 0.5 - player_pos * camera_zoom, 0.0, Vector2(camera_zoom, camera_zoom))
	_draw_ground()
	if location != "farm":
		Places.draw_world(self, location)
		if not truck_driving and truck_location == location: _draw_truck(truck_pos)
		_draw_player()
		_draw_interaction_marker()
		draw_set_transform(Vector2.ZERO)
		if weather in ["Lluvia", "Tormenta"]: _draw_rain(viewport)
		elif weather == "Nieve": _draw_snow(viewport)
		if minute > 1150.0 or minute < 390.0: draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.07,0.13,0.2,0.30), true)
		return
	_draw_paths_and_water()
	_draw_farmland()
	var drawables: Array[Dictionary] = props.duplicate()
	drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.tile.y < b.tile.y)
	var player_depth: float = player_pos.y + 6.0
	for prop: Dictionary in drawables:
		if float(prop.tile.y * TILE + 27) <= player_depth: _draw_prop(prop)
	_draw_buildings()
	if not truck_driving and truck_location == location: _draw_truck(truck_pos)
	_draw_crops()
	_draw_player()
	for prop: Dictionary in drawables:
		if float(prop.tile.y * TILE + 27) > player_depth: _draw_prop(prop)
	_draw_particles()
	_draw_target()
	draw_set_transform(Vector2.ZERO)
	if weather in ["Lluvia", "Tormenta"]: _draw_rain(viewport)
	elif weather == "Nieve": _draw_snow(viewport)
	if minute > 1150.0 or minute < 390.0: draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.07,0.13,0.2,0.30), true)
	var ambience: Color = [Color(0.95,0.87,0.66,0.035),Color(1.0,0.86,0.59,0.055),Color(0.88,0.63,0.40,0.075),Color(0.74,0.87,0.94,0.10)][season_index]
	draw_rect(Rect2(Vector2.ZERO, viewport), ambience, true)
	if sleeping: _draw_sleep_transition(viewport)

func _draw_ground() -> void:
	var view := get_viewport_rect().size
	var min_x: int = maxi(0, floori((player_pos.x - view.x * 0.5 / camera_zoom) / TILE) - 1)
	var max_x: int = mini(MAP_SIZE.x, ceili((player_pos.x + view.x * 0.5 / camera_zoom) / TILE) + 1)
	var min_y: int = maxi(0, floori((player_pos.y - view.y * 0.5 / camera_zoom) / TILE) - 1)
	var max_y: int = mini(MAP_SIZE.y, ceili((player_pos.y + view.y * 0.5 / camera_zoom) / TILE) + 1)
	for y: int in range(min_y, max_y):
		for x: int in range(min_x, max_x):
			var p := Vector2(x * TILE, y * TILE)
			var tint := Color.WHITE
			if season_index == 1: tint = Color("e4edbe")
			elif season_index == 2: tint = Color("d9bb85")
			elif season_index == 3: tint = Color("b8c9cb")
			if y < 4 or x < 4 or x > 49 or y > 36: tint = tint.darkened(0.13)
			_draw_terrain_tile(p, 0, tint)

# Stable coordinate hash keeps variation consistent between frames and saved games.
func _draw_terrain_tile(p: Vector2, material: int, tint: Color = Color.WHITE) -> void:
	var tile := Vector2i(p / float(TILE))
	var variant: int = posmod((tile.x * 73) ^ (tile.y * 151) ^ (tile.x * tile.y * 7), 4)
	var column: int = variant
	var row: int = material
	if material >= 3:
		row = 3
		column = variant % 2 + (2 if material == 4 else 0)
	draw_texture_rect_region(TERRAIN_ATLAS, Rect2(p, Vector2(TILE, TILE)), Rect2(column * TILE, row * TILE, TILE, TILE), tint)

func _draw_paths_and_water() -> void:
	# Sendero crema que serpentea desde la casa hasta el camino del pueblo.
	for y: int in range(9, 38):
		var center_x: float = 21.0 - sin(float(y) * 0.23) * 2.7
		for dx: int in range(-1, 2):
			var p := Vector2((int(center_x) + dx) * TILE, y * TILE)
			_draw_surface_tile(p, 0 if dx == 0 else 3)
	Places.draw_road(self, "farm")
	# Arroyo de la ampliación, con orilla de arena y reflejos dibujados en píxeles.
	for y: int in range(4, 13):
		for x: int in range(39, 48):
			var p := Vector2(x*TILE, y*TILE)
			var edge: bool = x == 39 or x == 47 or y == 4 or y == 12
			draw_rect(Rect2(p, Vector2(TILE,TILE)), Color("d4c18a") if edge else (Color("77c6c0") if posmod(x+y,3) == 0 else Color("63afb0")), true)
			if not edge and posmod(x*5+y*7,4) == 0:
				draw_line(p+Vector2(8,12),p+Vector2(22,12),Color("c5eee1",0.7),2)

func _draw_road_tile(p: Vector2, tile: Vector2i) -> void:
	_draw_surface_tile(p, 1)
	if tile.y == Places.ROAD_FIRST_ROW + 1 and tile.x % 2 == 0:
		draw_rect(Rect2(p + Vector2(5,15), Vector2(20,2)), Color("ead6a0"))

func _draw_surface_tile(p: Vector2, material: int) -> void:
	var tile := Vector2i(p / float(TILE))
	var variant: int = posmod((tile.x * 73) ^ (tile.y * 151), 4)
	draw_texture_rect_region(SURFACE_ATLAS, Rect2(p,Vector2(TILE,TILE)), Rect2(variant*TILE,material*TILE,TILE,TILE))

func _draw_farmland() -> void:
	for y: int in range(14, 27):
		for x: int in range(17, 29):
			var tile := Vector2i(x,y); var p := Vector2(x*TILE,y*TILE)
			var key := _tile_key(tile); var plot: Dictionary = plots.get(key,{})
			var inside: bool = x >= 18 and x <= 27 and y >= 15 and y <= 25
			if inside:
				if not plot.is_empty():
					var soil: String = String(plot.get("soil", "tilled"))
					var crop_id: String = String(plot.get("crop_id", ""))
					var texture_index: int = 1 if soil == "cleared" else 2
					if not crop_id.is_empty() and int(plot.get("growth",0)) == 0: texture_index = 3
					var tint: Color = Color("929aa2") if soil == "wet" else Color.WHITE
					_draw_terrain_tile(p, texture_index + 1, tint)
				elif posmod(x*7+y*13, 9) == 0:
					_draw_terrain_tile(p, 1)
				elif posmod(x*13+y*9, 17) == 0:
					_draw_terrain_tile(p, 2, Color("dce9b8"))
			else:
				# Suelo exterior cubierto de hierba alta; el sendero queda despejado.
				if not _is_path(tile) and posmod(x * 17 + y * 23, 5) != 0:
					_draw_terrain_tile(p, 1, Color("e3efcf"))
				if (x == 17 or x == 28 or y == 14 or y == 26) and posmod(x+y,3) == 0:
					draw_circle(p+Vector2(16,13),2.2,Color("f4d890"))
	# Valla rústica con puerta de entrada al sur.
	for x: int in range(17,29):
		if x >= 20 and x <= 22: continue
		_draw_fence(Vector2(x*TILE+16,27*TILE+12),true)
	for y: int in range(15,27):
		_draw_fence(Vector2(16*TILE+18,y*TILE+16),false)
		if owned_parcels < 2: _draw_fence(Vector2(29*TILE-18,y*TILE+16),false)
	if owned_parcels >= 2:
		for x: int in range(29,40): _draw_fence(Vector2(x*TILE+16,14*TILE+12),true)
		for x: int in range(29,40): _draw_fence(Vector2(x*TILE+16,27*TILE+12),true)
		for y: int in range(15,27): _draw_fence(Vector2(40*TILE-18,y*TILE+16),false)

func _draw_fence(p: Vector2, horizontal: bool) -> void:
	var texture: Texture2D = FARM_OBJECTS["fence_horizontal" if horizontal else "fence_vertical"]
	var size := Vector2(34, 24) if horizontal else Vector2(20, 36)
	draw_texture_rect(texture, Rect2(p - size * 0.5, size), false)

func _draw_buildings() -> void:
	var p := Vector2(20*TILE,13*TILE)
	_draw_ellipse(p+Vector2(64,83),Vector2(65,12),Color("3c5540",0.3))
	draw_texture_rect(FARMHOUSE_TEXTURE, Rect2(p+Vector2(-8,-48),Vector2(144,144)), false)
	# These keep the existing interaction positions and the entrance clear.
	draw_texture_rect(FARM_OBJECTS["barrel"], Rect2(p+Vector2(-36,40),Vector2(28,34)), false)
	draw_texture_rect(FARM_OBJECTS["grain_sacks"], Rect2(p+Vector2(130,58),Vector2(36,30)), false)
	draw_texture_rect(FARM_OBJECTS["bench"], Rect2(p+Vector2(132,18),Vector2(48,30)), false)
	var shop := Vector2(29*TILE,14*TILE)
	_draw_ellipse(shop+Vector2(48,68),Vector2(50,11),Color("435a43",0.3))
	draw_texture_rect(FARM_OBJECTS["market_stand"], Rect2(shop+Vector2(-8,-20),Vector2(112,96)), false)
	var well := Vector2(31*TILE,18*TILE)
	_draw_ellipse(well+Vector2(16,25),Vector2(23,8),Color("334b3f",0.3))
	draw_texture_rect(FARM_OBJECTS["well"], Rect2(well+Vector2(-12,-30),Vector2(56,60)), false)
	if owned_parcels < 2:
		var sign := Vector2(29*TILE+3,20*TILE)
		draw_texture_rect(FARM_OBJECTS["wooden_sign"], Rect2(sign+Vector2(-4,-2),Vector2(40,48)), false)
		draw_string(ThemeDB.fallback_font,sign+Vector2(4,25),"450",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("fff0c6"))
	_draw_produce_boxes()

func _draw_produce_boxes() -> void:
	draw_rect(Rect2(Vector2(28*TILE-8, 17*TILE-19), Vector2(120,15)), Color("293c32",0.9), true)
	draw_string(ThemeDB.fallback_font, Vector2(28*TILE-3, 17*TILE-8), "CAJAS DE COSECHA · 5", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f3e5be"))
	for index: int in range(produce_box_tiles.size()):
		var tile: Vector2i = produce_box_tiles[index]
		var box: Dictionary = produce_boxes[index] if index < produce_boxes.size() else {"crop_id":"", "count":0}
		var p := Vector2(tile * TILE)
		if index == moving_box_index and not mouse_dragging_box: continue
		draw_texture_rect(PRODUCE_CRATE_TEXTURE, _box_bounds(tile), false, Color.WHITE)
		var count: int = int(box.get("count", 0))
		if count > 0:
			var fruit_color := _fruit_color(String(box.get("crop_id", "turnip")))
			for fruit_index: int in range(count):
				draw_circle(p + Vector2(11 + fruit_index * 4, 7), 2.1, fruit_color)
				draw_line(p + Vector2(11 + fruit_index * 4, 5), p + Vector2(12 + fruit_index * 4, 3), Color("9cb85e"), 1)
		var count_color: Color = Color("f4e4bd") if count < 5 else Color("c8e17c")
		draw_string(ThemeDB.fallback_font, p + Vector2(6, 27), "%d/5" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, count_color)

func _draw_prop(prop: Dictionary) -> void:
	var tile: Vector2i = prop.tile
	if _is_path(tile): return
	var p := Vector2(tile*TILE)
	var species: String = Fruit.species(prop)
	if not species.is_empty():
		var ripe: bool = int(prop.get("fruit_count", 0)) > 0
		var sprite: Texture2D = FRUIT_TEXTURES[species][1 if ripe else 0]
		var size := TREE_DRAW_SIZE if prop.kind == "tree" else GROUND_PROP_DRAW_SIZE
		draw_texture_rect(sprite, Rect2(p + Vector2(16 - size.x * 0.5, 32 - size.y), size), false)
		return
	match String(prop.kind):
		"tree": _draw_tree(p, int(prop.variant))
		"stump": _draw_stump(p)
		"rock": _draw_rock(p, int(prop.variant))
		"bush": _draw_ground_prop(p, 3 + posmod(int(prop.variant),3))
		"weed": _draw_weed(p, int(prop.variant))
		"house": pass

func _draw_tree(p: Vector2, variant: int) -> void:
	var sprite: Texture2D = TREE_TEXTURES["apple"] if variant == 2 else TREE_TEXTURES["oak"]
	var tint := Color.WHITE
	if season_index == 2: tint = Color("f0d59a")
	elif season_index == 3: tint = Color("c7d3ca")
	draw_texture_rect(sprite,Rect2(p+Vector2(16-TREE_DRAW_SIZE.x*0.5,32-TREE_DRAW_SIZE.y),TREE_DRAW_SIZE),false,tint)

func _draw_stump(p: Vector2) -> void:
	_draw_ellipse(p+Vector2(16,24),Vector2(18,8),Color("3b533d",0.4))
	draw_rect(Rect2(p+Vector2(8,11),Vector2(17,12)),Color("82583c"),true)
	_draw_ellipse(p+Vector2(16,11),Vector2(10,7),Color("c39763"))
	_draw_ellipse(p+Vector2(16,11),Vector2(5,3.5),Color("806045"))

func _draw_rock(p: Vector2, variant: int) -> void:
	_draw_ground_prop(p, posmod(variant,3))

func _draw_weed(p: Vector2, variant: int) -> void:
	_draw_ground_prop(p, 6 + posmod(variant,3))

func _draw_ground_prop(p: Vector2, texture_index: int) -> void:
	var sprite: Texture2D = GROUND_PROP_TEXTURES[clampi(texture_index,0,GROUND_PROP_TEXTURES.size()-1)]
	draw_texture_rect(sprite,Rect2(p+Vector2(16-GROUND_PROP_DRAW_SIZE.x*0.5,32-GROUND_PROP_DRAW_SIZE.y),GROUND_PROP_DRAW_SIZE),false,Color.WHITE)

func _draw_crops() -> void:
	var view := get_viewport_rect().size
	var min_x: int = floori((player_pos.x - view.x * 0.5 / camera_zoom) / TILE) - 1
	var max_x: int = ceili((player_pos.x + view.x * 0.5 / camera_zoom) / TILE) + 1
	var min_y: int = floori((player_pos.y - view.y * 0.5 / camera_zoom) / TILE) - 1
	var max_y: int = ceili((player_pos.y + view.y * 0.5 / camera_zoom) / TILE) + 1
	for key: Variant in plots.keys():
		var parts: PackedStringArray = String(key).split(",")
		if parts.size() != 2: continue
		var crop_x: int = int(parts[0]); var crop_y: int = int(parts[1])
		if crop_x < min_x or crop_x > max_x or crop_y < min_y or crop_y > max_y: continue
		var p := Vector2(crop_x*TILE, crop_y*TILE)
		var plot: Dictionary = plots[key]
		if String(plot.get("crop_id", "")).is_empty():
			if plot.soil == "fertile":
				for j: int in range(4): draw_circle(p+Vector2(7+j*6,8+(j%2)*13),1.3,Color("e4cf80"))
			continue
		if plot.wilted: _draw_wilted(p); continue
		var crop: Dictionary = CropDB.by_id(String(plot.crop_id)); if crop.is_empty(): continue
		var growth: int = int(plot.growth); var days: int = int(crop.days)
		var watered: bool = bool(plot.get("watered", false))
		var stage: int = 0 if growth <= 0 else (1 if growth < days*0.34 else (2 if growth < days*0.7 else (3 if growth < days else 4)))
		_draw_crop_moisture(p, watered)
		var plant: Texture2D = _crop_icon(crop, "plant")
		if plant != null and stage > 0:
			var size: float = [12.0,22.0,30.0,38.0,46.0][stage]
			var tint := Color.WHITE if watered else Color("b6a47a")
			if stage < 4: tint = tint * Color("b4cf9b")
			draw_texture_rect(plant, Rect2(p + Vector2(16-size*0.5,32-size), Vector2(size,size)), false, tint)
		else:
			_draw_crop_sprite(p, String(crop.id), stage, int(crop.get("repeat",0)) > 0, watered)
		_draw_crop_water_badge(p, watered)

func _draw_crop_moisture(p: Vector2, watered: bool) -> void:
	# Contraste del suelo además del estado de las hojas: humedad azul, seco agrietado.
	if watered:
		draw_rect(Rect2(p + Vector2(3, 27), Vector2(26, 3)), Color("55a9ad", 0.8), true)
		draw_circle(p + Vector2(8, 25), 2.0, Color("a5e2dd", 0.9))
		draw_circle(p + Vector2(25, 24), 1.6, Color("a5e2dd", 0.85))
	else:
		draw_line(p + Vector2(5, 28), p + Vector2(11, 26), Color("6e4934", 0.95), 1.5)
		draw_line(p + Vector2(11, 26), p + Vector2(14, 29), Color("6e4934", 0.95), 1.5)
		draw_line(p + Vector2(24, 27), p + Vector2(28, 25), Color("6e4934", 0.95), 1.5)

func _draw_crop_water_badge(p: Vector2, watered: bool) -> void:
	var badge := p + Vector2(27, 5)
	if watered:
		draw_circle(badge, 5.0, Color("287c91", 0.98))
		draw_colored_polygon(PackedVector2Array([badge + Vector2(0,-3), badge + Vector2(2,0), badge + Vector2(0,3), badge + Vector2(-2,0)]), Color("c9f4ef"))
	else:
		draw_circle(badge, 5.0, Color("83533a", 0.98))
		draw_line(badge + Vector2(-2,1), badge + Vector2(0,-2), Color("f0c879"), 1.5)
		draw_line(badge + Vector2(0,-2), badge + Vector2(2,1), Color("f0c879"), 1.5)

func _draw_crop_sprite(p: Vector2, crop_id: String, stage: int, repeat: bool, watered: bool) -> void:
	var center := p+Vector2(16,20)
	var stem_height: float = [4.0,7.0,11.0,15.0,16.0][stage]
	if stage == 0:
		_draw_ellipse(center+Vector2(0,2),Vector2(6,3),Color("ab7d54"))
		var sprout: Color = Color("72b957") if watered else Color("9b8650")
		draw_line(center+Vector2(0,2),center+Vector2(0,-3 if watered else -1),sprout,2)
		if watered:
			draw_colored_polygon(PackedVector2Array([center+Vector2(0,-2),center+Vector2(-4,-5),center+Vector2(-1,-6)]),Color("8dcc62"))
		else:
			draw_circle(center+Vector2(0,0),1.2,Color("c3a967"))
		return
	var stem_color: Color = Color("497b4b") if watered else Color("88794b")
	draw_line(center+Vector2(0,6),center+Vector2(0,6-stem_height),stem_color,2)
	var leaves: int = 2 if stage < 3 else 4
	for i: int in range(leaves):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var y: float = 5.0 - float(i)*3.2 + (0.0 if watered else 2.0)
		var tip_y: float = y - (4.0 if watered else 1.0)
		var reach: float = 9.0 if watered else 7.0
		var leaf := PackedVector2Array([center+Vector2(0,y),center+Vector2(side*reach,y+tip_y-y),center+Vector2(side*(reach+2.0),y+2.0),center+Vector2(side*2,y+3.0)])
		var leaf_color: Color = (Color("75a854") if i % 2 == 0 else Color("94b65e")) if watered else (Color("a18a52") if i % 2 == 0 else Color("b4a064"))
		draw_colored_polygon(leaf,leaf_color)
	if stage >= 2:
		var crown_color := Color("6d9a4c") if watered else Color("a08b53")
		draw_circle(center+Vector2(-5,-4 if watered else -1),3,crown_color); draw_circle(center+Vector2(5,-1 if watered else 2),3,crown_color)
	if stage >= 4:
		var fruit_color: Color = _fruit_color(crop_id)
		if crop_id == "carrot":
			draw_colored_polygon(PackedVector2Array([center+Vector2(-2,-14),center+Vector2(5,-5),center+Vector2(1,5),center+Vector2(-3,-5)]),Color("e9904d"))
			draw_line(center+Vector2(0,-13),center+Vector2(-4,-19),Color("72a457"),2); draw_line(center+Vector2(0,-13),center+Vector2(5,-18),Color("8bad53"),2)
		elif crop_id == "turnip":
			_draw_ellipse(center+Vector2(0,-3),Vector2(7,8),Color("eee2c0")); draw_colored_polygon(PackedVector2Array([center+Vector2(-5,-7),center+Vector2(1,-8),center+Vector2(6,-4),center+Vector2(3,-1),center+Vector2(-5,-2)]),Color("a77a9b"))
		elif crop_id == "potato":
			_draw_ellipse(center+Vector2(-2,-3),Vector2(7,5),Color("c29b68")); draw_circle(center+Vector2(-4,-4),1.2,Color("7e6449")); draw_circle(center+Vector2(0,-1),1.0,Color("7e6449")); draw_circle(center+Vector2(2,-6),0.8,Color("7e6449"))
		elif crop_id == "wheat":
			for i: int in range(3):
				var stalk_x: float = float(i-1)*5.0
				draw_line(center+Vector2(stalk_x,6),center+Vector2(stalk_x-1,-13),Color("8caa4c"),2)
				for grain: int in range(3): _draw_ellipse(center+Vector2(stalk_x+(1 if grain%2==0 else -2),-12+grain*3),Vector2(2.2,1.3),Color("e2c66d"))
		elif crop_id == "garlic":
			_draw_ellipse(center+Vector2(-3,-2),Vector2(5,6),Color("eee2c3")); _draw_ellipse(center+Vector2(3,-2),Vector2(5,6),Color("f7edda")); draw_line(center+Vector2(0,-8),center+Vector2(1,-12),Color("b5a27d"),2)
		elif crop_id == "eggplant":
			_draw_ellipse(center+Vector2(0,-5),Vector2(6,10),Color("845482")); draw_colored_polygon(PackedVector2Array([center+Vector2(-4,-12),center+Vector2(0,-15),center+Vector2(4,-12),center+Vector2(1,-9)]),Color("6f984d"))
		elif crop_id == "strawberry":
			for berry: int in range(3):
				var bp := center+Vector2(float(berry-1)*7,-6.0+float(berry%2)*3.0)
				draw_circle(bp,4.3,Color("dd5d53")); draw_circle(bp+Vector2(-1,-1),0.9,Color("f2d887")); draw_circle(bp+Vector2(2,1),0.8,Color("f2d887"))
		elif crop_id == "corn":
			draw_rect(Rect2(center+Vector2(-3,-12),Vector2(7,13)),Color("e5c54f"),true); draw_line(center+Vector2(0,-9),center+Vector2(0,-1),Color("f3dc83"),2)
		elif crop_id == "pumpkin" or crop_id == "melon":
			_draw_ellipse(center+Vector2(0,-2),Vector2(10,7),fruit_color); draw_line(center+Vector2(0,-9),center+Vector2(1,-12),Color("476f42"),2)
		else:
			draw_circle(center+Vector2(-6,-7),4.5,fruit_color); draw_circle(center+Vector2(5,-7),4.5,fruit_color); draw_circle(center+Vector2(0,-12),4,fruit_color)
		if repeat: draw_circle(center+Vector2(11,-5),3.5,fruit_color.darkened(0.1))

func _fruit_color(id: String) -> Color:
	match id:
		"apple": return Color("df4a38")
		"pear": return Color("d8c74e")
		"wild_berries", "raspberry": return Color("ce4262")
		"strawberry": return Color("db6254")
		"tomato": return Color("df6549")
		"carrot": return Color("e9954e")
		"potato": return Color("bd9863")
		"lettuce", "spinach", "garlic": return Color("8fae59")
		"pepper": return Color("dc7d49")
		"eggplant": return Color("875a87")
		"blueberry": return Color("686db2")
		"melon": return Color("8ca95d")
		"wheat": return Color("e2c66d")
		"pumpkin": return Color("e99b4e")
		_: return Color("d47652")

func _draw_wilted(p: Vector2) -> void:
	draw_line(p+Vector2(16,24),p+Vector2(15,13),Color("76604b"),2)
	draw_colored_polygon(PackedVector2Array([p+Vector2(15,18),p+Vector2(7,20),p+Vector2(9,23)]),Color("90794d"))
	draw_colored_polygon(PackedVector2Array([p+Vector2(15,17),p+Vector2(24,19),p+Vector2(22,22)]),Color("a18a55"))

func _draw_player() -> void:
	if truck_driving:
		_draw_truck(player_pos)
		return
	draw_ellipse_shadow(player_pos)
	if action_time > 0.0 and PLAYER_ACTION_ROWS.has(player_animation):
		var row: int = int(PLAYER_ACTION_ROWS[player_animation])
		var frame: int = clampi(floori((0.36-action_time)*12.0),0,3)
		var source := Rect2(frame*32,row*48,32,48)
		var destination := Rect2(player_pos+Vector2(-16,-40),Vector2(32,48))
		var action_texture: Texture2D = PLAYER_ACTIONS_LEFT if facing.x < -0.25 else PLAYER_ACTIONS
		draw_texture_rect_region(action_texture,destination,source)
		_draw_carried_fruit()
		_draw_carried_box()
		return
	var direction_row: int = 0 if facing.y > 0.42 else (3 if facing.y < -0.42 else (1 if facing.x < 0.0 else 2))
	var frame: int = posmod(int(walk_phase * 0.55), 4) if player_animation == "walk" else (posmod(int(action_time * 8.0), 4) if action_time > 0.0 else 0)
	var source := Rect2i(frame * 32, direction_row * 48, 32, 48)
	var destination := Rect2(player_pos + Vector2(-16,-40), Vector2(32,48))
	draw_texture_rect_region(FARMER_TEXTURE, destination, source)
	_draw_carried_fruit()
	_draw_carried_box()

func draw_ellipse_shadow(center: Vector2) -> void:
	var points := PackedVector2Array()
	for i: int in range(16):
		var angle := TAU * float(i) / 16.0
		points.append(center + Vector2(cos(angle) * 10.0, sin(angle) * 3.0 + 3.0))
	draw_colored_polygon(points, Color(0.12, 0.18, 0.12, 0.24))

func _draw_carried_fruit() -> void:
	if carried_crop_count <= 0: return
	var hand_offset := Vector2(13,-16)
	if facing.x < -0.35: hand_offset = Vector2(-13,-16)
	elif facing.y > 0.35: hand_offset = Vector2(9,0)
	elif facing.y < -0.35: hand_offset = Vector2(9,-25)
	var center := player_pos + hand_offset
	var produce: Texture2D = _crop_icon(CropDB.by_id(carried_crop_id), "product")
	if produce != null:
		draw_texture_rect(produce, Rect2(center + Vector2(-10,-13),Vector2(20,20)),false)
	else:
		var fruit_color := _fruit_color(carried_crop_id)
		for i: int in range(mini(carried_crop_count, 2)):
			var shift := Vector2(float(i) * 5.0, float(i) * -2.0)
			draw_rect(Rect2(center + shift + Vector2(-4,-4), Vector2(9,8)), fruit_color.darkened(0.28), true)
			draw_rect(Rect2(center + shift + Vector2(-3,-5), Vector2(7,7)), fruit_color, true)
			draw_rect(Rect2(center + shift + Vector2(-1,-6), Vector2(3,2)), Color("f5d28a", 0.9), true)
			draw_colored_polygon(PackedVector2Array([center+shift+Vector2(-1,-5),center+shift+Vector2(1,-9),center+shift+Vector2(4,-7)]), Color("8eb45a"))
	if carried_crop_count > 1:
		draw_circle(center + Vector2(7,-9), 6, Color("293c32"))
		draw_string(ThemeDB.fallback_font, center + Vector2(4,-6), str(carried_crop_count), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _draw_carried_box() -> void:
	if moving_box_index < 0 or mouse_dragging_box: return
	var hand_offset := Vector2(12,-31)
	if facing.x < -0.35: hand_offset = Vector2(-12,-31)
	var rect := Rect2(player_pos + hand_offset + Vector2(-14,-9), Vector2(28,21))
	draw_texture_rect(PRODUCE_CRATE_TEXTURE, rect, false, Color.WHITE)
	var count: int = int(produce_boxes[moving_box_index].get("count", 0))
	if count > 0:
		var color := _fruit_color(String(produce_boxes[moving_box_index].get("crop_id", "turnip")))
		for i: int in range(count): draw_circle(rect.position + Vector2(9 + i * 2.4, 7), 1.3, color)

func _draw_truck(position: Vector2) -> void:
	var direction := "down"
	if absf(truck_facing.x) > absf(truck_facing.y):
		direction = "right" if truck_facing.x > 0.0 else "left"
	elif truck_facing.y < 0.0:
		direction = "up"
	var truck_size := Vector2(116, 62) if direction in ["left", "right"] else Vector2(78, 98)
	var rect := Rect2(position - truck_size * 0.5, truck_size)
	draw_texture_rect(FARM_TRUCK_TEXTURES[direction], rect, false, Color.WHITE)
	for index: int in range(truck_cargo.size()):
		var row := index / 3
		var col := index % 3
		var crate_offset := Vector2(-19 + col * 13, -43 + row * 12)
		match direction:
			"up": crate_offset = Vector2(19 - col * 13, 23 + row * 12)
			"left": crate_offset = Vector2(18 + col * 13, -12 + row * 13)
			"right": crate_offset = Vector2(-44 + col * 13, -12 + row * 13)
		var crate_pos := position + crate_offset
		draw_texture_rect(PRODUCE_CRATE_TEXTURE, Rect2(crate_pos, Vector2(12, 11)), false, Color.WHITE)
		var produce_color := _fruit_color(String(truck_cargo[index].get("crop_id", "turnip")))
		draw_circle(crate_pos + Vector2(6, 5), 2.0, produce_color)
	if truck_cargo.size() > 0:
		var cargo_badge_offset := Vector2(28, -38)
		if direction == "left": cargo_badge_offset = Vector2(48, -22)
		elif direction == "right": cargo_badge_offset = Vector2(-48, -22)
		draw_circle(position + cargo_badge_offset, 9, Color("293c32", 0.94))
		draw_string(ThemeDB.fallback_font, position + cargo_badge_offset + Vector2(-3, 3), str(truck_cargo.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f6e3b7"))

func _draw_interaction_marker() -> void:
	var context := _primary_target()
	if context.get("action", "") == "work":
		context["point"] = Vector2(context.tile * TILE) + Vector2(16,16)
	if not context.is_empty() and context.has("point"):
		var point: Vector2 = context.point
		draw_arc(point, 23.0, 0.0, TAU, 32, Color("fff1b8",0.9), 2.0)

func _draw_target() -> void:
	_draw_interaction_marker()
	var p := Vector2(_target_tile())*TILE
	var can_work: bool = _tile_in_reach(_target_tile()) and _can_use_land(_target_tile())
	var color: Color = Color("f3dc8d",0.9) if can_work else Color("e08061",0.8)
	if tool_charge > 0.1 and int(tool_levels.get(tool_names[selected_tool], 1)) >= 2 and tool_names[selected_tool] in ["Azada", "Regadera"]:
		var outline: Color = Color("f3dc8d",0.42 + minf(tool_charge,1.0)*0.28)
		for y: int in range(-1,2):
			for x: int in range(-1,2):
				draw_rect(Rect2(p+Vector2(x*TILE+2,y*TILE+2),Vector2(28,28)),outline,false,1.5)
	draw_rect(Rect2(p+Vector2(2,2),Vector2(28,28)),Color(color.r,color.g,color.b,0.15),true)
	draw_rect(Rect2(p+Vector2(2,2),Vector2(28,28)),color,false,2.0)
	draw_line(p+Vector2(12,16),p+Vector2(20,16),color,1)
	draw_line(p+Vector2(16,12),p+Vector2(16,20),color,1)

func _draw_sleep_transition(viewport: Vector2) -> void:
	var t: float = sleep_transition_time
	if t < 1.15:
		var darkness: float = 0.9 * clampf(t / 0.75, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.025, 0.045, 0.075, darkness), true)
		for i: int in range(9):
			var x: float = fposmod(float(i * 173 + 61), viewport.x)
			var bob: float = sin(t * 3.0 + float(i)) * 5.0
			draw_circle(Vector2(x, 80.0 + float(i % 4) * 52.0 + bob), 1.5, Color(1.0, 0.92, 0.65, darkness))
		var z_alpha: float = clampf((t - 0.35) / 0.35, 0.0, 1.0)
		var z_y: float = viewport.y * 0.5 - 22.0 - fposmod(t * 20.0, 24.0)
		draw_string(ThemeDB.fallback_font, Vector2(viewport.x * 0.5, z_y), "Z  z  z", HORIZONTAL_ALIGNMENT_CENTER, -1, 26, Color("f5e9c9", z_alpha))
	else:
		var morning: float = clampf((t - 1.15) / 1.05, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.025, 0.045, 0.075, 0.9 * (1.0 - morning)), true)
		draw_rect(Rect2(Vector2.ZERO, viewport), Color("f5c66d", 0.24 * morning), true)
		var sun_center := Vector2(viewport.x * 0.78, viewport.y * 0.72 - morning * 64.0)
		draw_circle(sun_center, 30.0 * morning, Color("ffe6a0", 0.9 * morning))
		var title_alpha := clampf((morning - 0.3) / 0.45, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(viewport.x * 0.5, viewport.y * 0.48), "¡Buenos días!", HORIZONTAL_ALIGNMENT_CENTER, -1, 34, Color("fff4d4", title_alpha))
		draw_string(ThemeDB.fallback_font, Vector2(viewport.x * 0.5, viewport.y * 0.48 + 35), "Día %02d · %s" % [day, SEASONS[season_index]], HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color("fff4d4", title_alpha))

func _target_tile_center() -> Vector2:
	return Vector2(_target_tile())*TILE+Vector2(16,16)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in range(20):
		var angle: float = TAU * float(i) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _draw_particles() -> void:
	for particle: Dictionary in particles:
		var alpha: float = clampf(float(particle.life) / 0.48,0.0,1.0)
		var color: Color = particle.color
		color.a *= alpha
		var position: Vector2 = particle.pos
		draw_colored_polygon(PackedVector2Array([position+Vector2(0,-2),position+Vector2(2,0),position+Vector2(0,2),position+Vector2(-2,0)]),color)

func _draw_rain(viewport: Vector2) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = int(Time.get_ticks_msec()/90)
	for i: int in range(48):
		var x: float = rng.randf_range(0.0,viewport.x); var y: float = rng.randf_range(0.0,viewport.y)
		draw_line(Vector2(x,y),Vector2(x-5,y+14),Color("c1e6db",0.33),1)

func _draw_snow(viewport: Vector2) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = int(Time.get_ticks_msec()/150)
	for i: int in range(55):
		var x: float = rng.randf_range(0.0,viewport.x); var y: float = rng.randf_range(0.0,viewport.y)
		draw_circle(Vector2(x,y),rng.randf_range(1.0,2.1),Color("eef4e8",0.72))

func _menu_button(text: String, action: Callable, disabled: bool = false) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.disabled = disabled
	button.pressed.connect(action)
	modal_body.add_child(button)

func _populate_title() -> void:
	modal_title.text = "✿ FARM LIFE"
	_add_note("Tu granja, a tu ritmo. Un nuevo día te espera entre el campo, el río y el pueblo.")
	var data: Dictionary = Saves.load_game()
	if not data.is_empty():
		_add_note("Día %d · %s · %d monedas · %s" % [int(data.get("day", 1)), SEASONS[posmod(int(data.get("season", 0)), 4)], int(data.get("coins", 180)), Places.NAMES.get(String(data.get("location", "farm")), "La granja")])
	_menu_button("Continuar partida" if not data.is_empty() else "Continuar · sin partida guardada", _load_saved_game, data.is_empty())
	_menu_button("Nueva partida", _title_new_game)
	_menu_button("Controles y ayuda", _show_controls)
	_menu_button("Salir del juego", _exit_game)
	_add_note("1280 × 800 · Juega con mando, teclado o ratón.")

func _title_new_game() -> void:
	confirmation_back = "title"
	if Saves.load_game().is_empty(): _start_new_game()
	else: _open_modal("confirm_new")

func _return_to_title() -> void:
	confirmation_back = "pause"
	_populate_title_confirmation()

func _populate_title_confirmation() -> void:
	_open_modal("confirm_title")
	_populate_confirmation("¿Volver al inicio?", "Los cambios sin guardar se perderán al cargar otra partida. Puedes cancelar y guardar desde la pausa.", func() -> void:
		at_title = true
		_open_modal("title"))
	var first: Control = _first_focusable(modal_body)
	if first != null and is_inside_tree(): first.grab_focus()

func _cancel_confirmation() -> void:
	if confirmation_back == "": _close_modal()
	else: _open_modal(confirmation_back)

func _populate_travel() -> void:
	modal_title.text = "Los caminos del valle"
	_add_note("Estás en %s. Camioneta aparcada en %s." % [Places.NAMES[location], Places.NAMES[truck_location]])
	_add_note("A pie: 30 minutos y 5 de energía. En coche: 10 minutos. La carga viaja contigo en la camioneta.")
	if moving_box_index >= 0: _add_note("Deja la caja en el suelo antes de viajar.")
	var can_drive: bool = truck_location == location and (truck_driving or player_pos.distance_to(truck_pos) < 100.0) and carried_crop_count == 0
	if not can_drive: _add_note("Para ir en coche, acércate a tu camioneta con las manos libres.")
	for destination: String in ["farm", "river", "town"]:
		if destination == location: continue
		_menu_button("%s · Ir andando" % Places.NAMES[destination], _travel_to.bind(destination, false), moving_box_index >= 0 or energy < 5.0)
		_menu_button("%s · Ir en coche" % Places.NAMES[destination], _travel_to.bind(destination, true), moving_box_index >= 0 or not can_drive)
	_menu_button("Seguir aquí", _close_modal)

func _try_road_exit(move: Vector2) -> bool:
	if at_title or sleeping or modal != "" or road_exit_cooldown > 0.0 or not Places.on_road(player_pos): return false
	var direction := 0
	if move.x < -0.12 and player_pos.x <= Places.EXIT_LEFT: direction = -1
	elif move.x > 0.12 and player_pos.x >= Places.EXIT_RIGHT: direction = 1
	if direction == 0: return false
	var destination := Places.road_destination(location, direction)
	if destination.is_empty(): return false
	road_exit_cooldown = 1.0
	if moving_box_index >= 0:
		_show_toast("Deja la caja antes de salir de la zona."); return false
	var previous := location
	_travel_to(destination, truck_driving, direction)
	if location == previous:
		if not truck_driving and energy < 5.0: _show_toast("Descansa un poco antes de seguir andando.")
		elif truck_driving and carried_crop_count > 0: _show_toast("Guarda la cosecha antes de viajar en coche.")
	return location != previous

func _travel_to(destination: String, by_car: bool, road_direction: int = 0) -> void:
	if not Places.NAMES.has(destination) or destination == location or moving_box_index >= 0: return
	if by_car and (truck_location != location or (not truck_driving and player_pos.distance_to(truck_pos) >= 100.0) or carried_crop_count > 0): return
	if not by_car and energy < 5.0: return
	var duration: float = 10.0 if by_car else 30.0
	if minute + duration >= 1440.0:
		_show_toast("Es demasiado tarde para salir. Espera al nuevo día."); return
	if truck_driving: truck_pos = player_pos
	truck_driving = by_car
	location = destination
	# Arrive at the opposite end, safely inside the next map. Holding the
	# direction continues the journey instead of immediately returning.
	player_pos = Vector2(192 if road_direction > 0 else (1536 if road_direction < 0 else 864), Places.ROAD_Y)
	if by_car:
		truck_location = destination
		truck_pos = player_pos
		truck_facing = Vector2(road_direction,0) if road_direction != 0 else Vector2.UP
	else:
		energy -= 5.0
		if truck_location == location and player_pos.distance_to(truck_pos) < 100.0: player_pos += Vector2(128 if player_pos.x < 864 else -128, 0)
	minute += duration
	move_vector = Vector2.ZERO
	mouse_aim_active = false
	aim_stick = Vector2.ZERO
	action_time = 0.0
	tool_charge = 0.0
	particles.clear()
	_close_modal()
	_show_toast("%s · %s · %d minutos" % [Places.NAMES[location], "en coche" if by_car else "a pie", int(duration)])
	_refresh_hud()
	queue_redraw()

func _interact_destination() -> void:
	_interact()

func _rest_at_river() -> void:
	_close_modal()
	minute += 20.0
	if minute >= 1440.0:
		minute -= 1440.0
		_advance_day()
	energy = minf(100.0, energy + 15.0)
	_show_toast("El sonido del río te ha sentado bien · +15 energía")
