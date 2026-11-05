extends RefCounted
class_name CropDatabase

const Visuals = preload("res://scripts/crop_visuals.gd")

const EXTENDED_NAMES := [
	"Tomate cherry","Cebolla","Puerro","Pimiento rojo","Pimiento amarillo","Calabacín","Pepino","Sandía","Brócoli","Coliflor","Repollo","Lombarda","Acelga","Remolacha","Rábano","Apio","Espárrago","Alcachofa","Judía verde","Guisante","Haba","Boniato","Frambuesa","Mora","Physalis","Grosella","Cebada","Avena","Arroz","Centeno","Garbanzo","Lenteja","Soja","Cacahuete","Albahaca","Perejil","Cilantro","Menta","Romero","Tomillo","Orégano","Lavanda","Girasol","Manzanilla","Lino","Manzano","Peral","Cerezo","Melocotonero","Ciruelo","Albaricoquero","Naranjo","Limonero","Mandarino","Olivo","Higuera","Granado","Nogal","Almendro","Avellano","Aguacatero","Kiwi","Caqui","Membrillo","Mango","Piña","Col rizada","Col de Bruselas","Chirivía","Escarola","Rúcula","Nabo morado","Ajo tierno","Endibia","Quinoa","Trébol","Colza","Mijo","Alforfón","Sésamo","Borraja"
]

static var _crop_cache: Dictionary = {}
static var _all_cache: Array[Dictionary] = []

const WILD_FRUITS: Array[Dictionary] = [
	{"id":"apple", "name":"Manzana", "category":"Fruta", "sell":38},
	{"id":"pear", "name":"Pera", "category":"Fruta", "sell":46},
	{"id":"wild_berries", "name":"Bayas silvestres", "category":"Fruta", "sell":22},
	{"id":"raspberry", "name":"Frambuesa", "category":"Fruta", "sell":28},
]

# Canonical catalog. Legacy constants above are retained only to read older saves.
static func all_crops() -> Array[Dictionary]:
	if not _all_cache.is_empty(): return _all_cache
	var result: Array[Dictionary] = []
	var data: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/crops.json"))
	for entry: Dictionary in data:
		var complete: Dictionary = _with_visuals(entry)
		if not complete.is_empty(): result.append(complete)
	_all_cache = result
	return result

static func crop_ids() -> Array[String]:
	var result: Array[String] = []
	for crop: Dictionary in all_crops(): result.append(String(crop.id))
	return result

static func by_id(crop_id: String) -> Dictionary:
	if _crop_cache.is_empty():
		for crop: Dictionary in all_crops():
			_crop_cache[crop.id] = crop
		# Keep saved catalog_NNN plots and seed stacks usable without adding duplicates to the shop.
		for i: int in range(EXTENDED_NAMES.size()):
			var legacy: Dictionary = {}
			for crop: Dictionary in all_crops():
				if crop.name == EXTENDED_NAMES[i]:
					legacy = crop.duplicate(true)
					break
			if legacy.is_empty():
				legacy = {"name":EXTENDED_NAMES[i],"category":"Cultivo antiguo","seed":18+(i*7)%31,"sell":34+(i*13)%91,"days":3+i%7,"season":["Primavera","Verano","Otoño","Invierno"][i%4],"repeat":i%5 if i%3==0 else 0}
			legacy.merge({"id":"catalog_%03d" % i,"seed":18+(i*7)%31,"sell":34+(i*13)%91,"days":3+i%7,"season":["Primavera","Verano","Otoño","Invierno"][i%4],"repeat":i%5 if i%3==0 else 0},true)
			_crop_cache[legacy.id] = _with_visuals(legacy)
		for fruit: Dictionary in WILD_FRUITS:
			_crop_cache[fruit.id] = _with_visuals(fruit.duplicate(true))
	return _crop_cache.get(crop_id, {})

static func crops_for_season(season: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for crop: Dictionary in all_crops():
		if crop.season == season:
			result.append(crop)
	return result

static func _with_visuals(crop: Dictionary) -> Dictionary:
	var crop_id: String = String(crop.get("id", ""))
	if not Visuals.has_complete_set(crop_id):
		push_error("%s: necesita los ocho sprites del contrato antes de incorporarse al juego." % crop_id)
		return {}
	var visual_id: String = Visuals.visual_id_for(crop_id)
	var entry: Dictionary = Visuals.entries()[visual_id]
	crop["visual_id"] = visual_id
	crop["sprite_sheet"] = entry.sheet
	crop["sprite_states"] = entry.frames.duplicate()
	# Older callers may still ask for one of these three icon roles.
	crop["product_sprite"] = entry.sheet
	crop["plant_sprite"] = entry.sheet
	crop["seed_sprite"] = entry.sheet
	return crop
