extends RefCounted

const NAMES: Dictionary = {"farm": "La granja", "river": "El río", "town": "El pueblo"}
# A single horizontal road connects the maps: river <-> farm <-> town.
const ROAD_FIRST_ROW: int = 34
const ROAD_LAST_ROW: int = 36
const ROAD_Y: float = 1136.0
const EXIT_LEFT: float = 80.0
const EXIT_RIGHT: float = 1648.0

static func on_road(pos: Vector2) -> bool:
	return pos.y >= ROAD_FIRST_ROW * 32 and pos.y < (ROAD_LAST_ROW + 1) * 32

static func road_destination(area: String, direction: int) -> String:
	if area == "farm": return "river" if direction < 0 else "town"
	if area == "river" and direction > 0: return "farm"
	if area == "town" and direction < 0: return "farm"
	return ""

const SHOP = preload("res://assets/sprites/travel/village_shop.png")
const BRIDGE = preload("res://assets/sprites/travel/river_bridge.png")
const DOCK = preload("res://assets/sprites/travel/fishing_dock.png")
const FOUNTAIN = preload("res://assets/sprites/travel/village_fountain.png")
const SHOP_RECT := Rect2(464, 352, 192, 192)
const FOUNTAIN_RECT := Rect2(832, 524, 128, 128)
const BRIDGE_RECT := Rect2(928, 416, 256, 128)
const DOCK_RECT := Rect2(848, 672, 176, 96)

static func blocked(area: String, pos: Vector2) -> bool:
	if pos.x < 64 or pos.x > 1664 or pos.y < 96 or pos.y > 1184: return true
	if on_road(pos): return false
	if area == "town":
		return SHOP_RECT.grow(-12).has_point(pos) or Rect2(1104, 352, 192, 176).has_point(pos) or Rect2(840, 560, 112, 80).has_point(pos)
	if pos.x >= 960 and pos.x <= 1152:
		return not Rect2(928, 460, 256, 46).has_point(pos) and not DOCK_RECT.grow(-16).has_point(pos)
	return false

static func draw_world(game: Node2D, area: String) -> void:
	# Paths are tiled with the same generated materials as the farm.
	for y: int in range(4, 37):
		for x: int in range(3, 51):
			var p := Vector2(x * 32, y * 32)
			if area == "town":
				if (x >= 12 and x <= 42 and y >= 16 and y <= 23) or (x >= 13 and x <= 16 and y >= 24):
					game._draw_surface_tile(p, 2)
				elif x >= 13 and x <= 16 and y >= 24:
					game._draw_surface_tile(p, 3)
			else:
				if x >= 29 and x <= 36:
					game.draw_rect(Rect2(p, Vector2(32, 32)), Color("d4c18a") if x in [29, 36] else Color("63afb0"))
					if x > 29 and x < 36:
						var shift := fmod(float(Time.get_ticks_msec()) * 0.012 + float(y * 7), 20.0)
						game.draw_line(p + Vector2(4, shift), p + Vector2(20, shift), Color("b4e1d5", 0.65), 2)
				elif (x >= 13 and x <= 16 and y >= 14) or (y >= 14 and y <= 16 and x >= 15 and x <= 44) or (x >= 16 and x <= 27 and y >= 20 and y <= 23):
					game._draw_surface_tile(p, 3)
	draw_road(game, area)
	for i: int in range(18):
		var tx: int = 5 + i * 7 % 44
		var ty: int = 6 + i * 11 % 29
		var p := Vector2(tx * 32, ty * 32)
		if p.y + 96 < ROAD_FIRST_ROW * 32 and (p.x < 380 or p.x > 1410 or p.y < 300) and not (area == "river" and p.x > 864 and p.x < 1184):
			game.draw_texture_rect(game.TREE_TEXTURES.oak, Rect2(p, Vector2(80,96)), false)
	if area == "town":
		game.draw_texture_rect(SHOP, SHOP_RECT, false)
		game.draw_texture_rect(game.FARMHOUSE_TEXTURE, Rect2(1104, 336, 192, 192), false)
		game.draw_texture_rect(FOUNTAIN, FOUNTAIN_RECT, false)
		_caption(game, Vector2(464, 330), "TIENDA DEL PUEBLO")
		_caption(game, Vector2(444, 584), "E / X · Comprar / vender carga")
		_caption(game, Vector2(814, 698), "E / X · Llenar regadera")
		game.draw_texture_rect(game.FARM_OBJECTS.bench, Rect2(720, 672, 72, 45), false)
	else:
		game.draw_texture_rect(BRIDGE, BRIDGE_RECT, false)
		game.draw_texture_rect(DOCK, DOCK_RECT, false)
		game.draw_texture_rect(game.FARM_OBJECTS.bench, Rect2(540, 616, 72, 45), false)
		_caption(game, Vector2(480, 596), "E / X · Descansar junto al río")
		_caption(game, Vector2(780, 800), "E / X · Llenar regadera")
		_caption(game, Vector2(880, 402), "PUENTE DEL SAUCE")


static func draw_road(game: Node2D, area: String) -> void:
	for y: int in range(ROAD_FIRST_ROW, ROAD_LAST_ROW + 1):
		for x: int in range(54):
			game._draw_road_tile(Vector2(x * 32, y * 32), Vector2i(x,y))
	var left := road_destination(area, -1)
	var right := road_destination(area, 1)
	if not left.is_empty():
		game.draw_texture_rect(game.FARM_OBJECTS.wooden_sign, Rect2(96,1036,40,48), false)
		_caption(game, Vector2(72,1020), "← " + String(NAMES[left]))
	if not right.is_empty():
		game.draw_texture_rect(game.FARM_OBJECTS.wooden_sign, Rect2(1592,1036,40,48), false)
		_caption(game, Vector2(1480,1020), String(NAMES[right]) + " →")

static func _caption(game: Node2D, pos: Vector2, text: String) -> void:
	game.draw_string(ThemeDB.fallback_font, pos + Vector2(1,2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("293c32"))
	game.draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff1ce"))
