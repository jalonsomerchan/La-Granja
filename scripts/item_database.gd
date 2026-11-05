extends RefCounted
class_name ItemDatabase

const DATA: Dictionary = {
	"wood":{"name":"Madera","sell":3,"description":"Se obtiene al talar árboles y retirar tocones. Sirve para tablones y mejoras del taller."},
	"stone":{"name":"Piedra","sell":3,"description":"Se obtiene al picar rocas. Se utiliza en mejoras de herramientas y ladrillos."},
	"fiber":{"name":"Fibra","sell":2,"description":"Se recoge al cortar maleza. Se utiliza para cuerda y abono."},
	"clay":{"name":"Arcilla","sell":4,"description":"Aparece en rocas de color terracota. Sirve para ladrillos y abono."},
	"coal":{"name":"Carbón","sell":6,"description":"Aparece en rocas oscuras. Es combustible para cocer ladrillos y fundir hierro."},
	"iron_ore":{"name":"Mineral de hierro","sell":9,"description":"Aparece en rocas con vetas ocres. Se funde con carbón para obtener lingotes."},
	"plank":{"name":"Tablón","sell":5,"description":"Madera aserrada. Se utiliza en vallas y mejoras de herramientas desde nivel 3."},
	"rope":{"name":"Cuerda","sell":7,"description":"Fibra trenzada. Sirve para fabricar vallas y mejorar herramientas desde nivel 3."},
	"brick":{"name":"Ladrillo","sell":9,"description":"Arcilla cocida con refuerzo de piedra. Se utiliza en los apoyos de las vallas."},
	"iron_bar":{"name":"Lingote de hierro","sell":25,"description":"Hierro fundido. Las mejoras de herramientas desde nivel 3 necesitan un lingote."},
	"fertilizer":{"name":"Abono","sell":4,"description":"Equípalo y pulsa A / E sobre tierra preparada. Mejora la probabilidad de calidad de la siguiente cosecha; no sustituye el riego.","use":"fertilize"},
	"fence":{"name":"Valla de madera","sell":12,"description":"Equípala y pulsa A / E sobre suelo libre de tu parcela. Bloquea el paso. Puedes recuperarla entera con el hacha.","use":"place"},
}
const ICONS: Dictionary = {
	"wood":preload("res://assets/sprites/items/wood.png"),"stone":preload("res://assets/sprites/items/stone.png"),
	"fiber":preload("res://assets/sprites/items/fiber.png"),"clay":preload("res://assets/sprites/items/clay.png"),
	"coal":preload("res://assets/sprites/items/coal.png"),"iron_ore":preload("res://assets/sprites/items/iron_ore.png"),
	"plank":preload("res://assets/sprites/items/plank.png"),"rope":preload("res://assets/sprites/items/rope.png"),
	"brick":preload("res://assets/sprites/items/brick.png"),"iron_bar":preload("res://assets/sprites/items/iron_bar.png"),
	"fertilizer":preload("res://assets/sprites/items/fertilizer.png"),"fence":preload("res://assets/sprites/items/fence.png"),
}
const RECIPES: Array[Dictionary] = [
	{"id":"plank","amount":2,"cost":{"wood":3}},
	{"id":"rope","amount":1,"cost":{"fiber":4}},
	{"id":"brick","amount":2,"cost":{"clay":3,"stone":1,"coal":1}},
	{"id":"iron_bar","amount":1,"cost":{"iron_ore":3,"coal":1}},
	{"id":"fertilizer","amount":3,"cost":{"fiber":2,"clay":1}},
	{"id":"fence","amount":2,"cost":{"plank":2,"rope":1,"brick":1}},
]

static func by_id(item: String) -> Dictionary:
	return DATA.get(item,{})

static func recipe(item: String) -> Dictionary:
	for entry: Dictionary in RECIPES:
		if entry.id == item: return entry
	return {}

static func max_batches(item: String, inventory: Dictionary) -> int:
	var entry: Dictionary = recipe(item)
	if entry.is_empty(): return 0
	var batches: int = 2147483647
	for ingredient: String in entry.cost:
		batches = mini(batches,maxi(0,int(inventory.get(ingredient,0)))/int(entry.cost[ingredient]))
	return batches

static func craft(item: String, batches: int, inventory: Dictionary) -> Dictionary:
	if batches <= 0 or batches > 99 or batches > max_batches(item,inventory): return {"ok":false}
	var entry: Dictionary = recipe(item)
	var next: Dictionary = inventory.duplicate(true)
	for ingredient: String in entry.cost: next[ingredient] = int(next.get(ingredient,0))-int(entry.cost[ingredient])*batches
	var amount: int = int(entry.amount)*batches
	next[item] = int(next.get(item,0))+amount
	return {"ok":true,"inventory":next,"amount":amount}

static func drops(prop: Dictionary) -> Dictionary:
	match String(prop.get("kind","")):
		"tree": return {"wood":5}
		"stump": return {"wood":2}
		"weed","bush": return {"fiber":1}
		"rock":
			var result: Dictionary = {"stone":3}
			var extra: String = rock_material(int(prop.get("variant",0)))
			if extra != "stone": result[extra] = 2
			return result
	return {}

static func rock_material(variant: int) -> String:
	return ["stone","clay","coal","iron_ore"][posmod(variant,4)]
