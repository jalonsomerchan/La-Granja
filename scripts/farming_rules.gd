extends RefCounted
class_name FarmingRules

static func can_plant(soil: String, crop: Dictionary, season: String, occupied: bool) -> bool:
	return soil in ["tilled", "wet", "fertile"] and not occupied and String(crop.get("season", "")) == season

static func daily_growth(plot: Dictionary, rain: bool) -> Dictionary:
	var result: Dictionary = plot.duplicate(true)
	if result.get("wilted", false):
		return result
	if bool(result.get("watered", false)) or rain:
		result["growth"] = int(result.get("growth", 0)) + 1
		result["dry_days"] = 0
		result["soil"] = "wet"
	else:
		result["dry_days"] = int(result.get("dry_days", 0)) + 1
		result["soil"] = "tilled"
		if int(result["dry_days"]) >= 3:
			result["wilted"] = true
	result["watered"] = false
	return result

static func is_ready(plot: Dictionary, crop: Dictionary) -> bool:
	return not bool(plot.get("wilted", false)) and int(plot.get("growth", 0)) >= int(crop.get("days", 1))

static func harvest(plot: Dictionary, crop: Dictionary) -> Dictionary:
	if not is_ready(plot, crop):
		return {"yield": 0, "plot": plot.duplicate(true)}
	var repeats: int = int(crop.get("repeat", 0))
	if repeats > 0:
		var next_plot: Dictionary = plot.duplicate(true)
		next_plot["growth"] = int(crop["days"]) - repeats
		next_plot["watered"] = false
		return {"yield": int(crop.get("yield", 2)), "plot": next_plot}
	return {"yield": int(crop.get("yield", 2)), "plot": {}}
