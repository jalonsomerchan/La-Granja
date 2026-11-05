extends RefCounted
class_name FruitRules

# Each plant owns its countdown; it does not depend on the calendar wrapping.
const SPECIES: Dictionary = {
	"apple": {"product":"apple", "min_days":3, "max_days":5},
	"pear": {"product":"pear", "min_days":4, "max_days":7},
	"berry": {"product":"wild_berries", "min_days":2, "max_days":4},
	"blueberry": {"product":"blueberry", "min_days":3, "max_days":5},
	"raspberry": {"product":"raspberry", "min_days":2, "max_days":4},
}

static func species(prop: Dictionary) -> String:
	var variant := int(prop.get("variant", 0))
	if prop.get("kind", "") == "tree":
		if variant == 2: return "apple"
		if variant in [1, 3]: return "pear"
	elif prop.get("kind", "") == "bush":
		return ["berry", "blueberry", "raspberry"][posmod(variant, 3)]
	return ""

static func reset(prop: Dictionary, rng: RandomNumberGenerator) -> void:
	var config: Dictionary = SPECIES.get(species(prop), {})
	if config.is_empty(): return
	prop["fruit_count"] = 0
	prop["fruit_days"] = rng.randi_range(int(config.min_days), int(config.max_days))

static func initialize(prop: Dictionary, rng: RandomNumberGenerator) -> void:
	if species(prop).is_empty() or prop.has("fruit_days"): return
	reset(prop, rng)
	if rng.randf() < 0.45:
		prop["fruit_count"] = rng.randi_range(2, 3)
		prop["fruit_days"] = 0

static func advance_day(prop: Dictionary, rng: RandomNumberGenerator) -> void:
	initialize(prop, rng)
	if species(prop).is_empty() or int(prop.get("fruit_count", 0)) > 0: return
	prop["fruit_days"] = maxi(0, int(prop["fruit_days"]) - 1)
	if int(prop["fruit_days"]) == 0:
		prop["fruit_count"] = rng.randi_range(2, 3)
