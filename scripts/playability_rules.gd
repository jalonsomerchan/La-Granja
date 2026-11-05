extends RefCounted

# Inventory includes produce in physical crates. Cargo has already been removed.
static func loose_count(crop_id: String, inventory: Dictionary, boxes: Array) -> int:
	var count: int = int(inventory.get(crop_id, 0))
	for box: Dictionary in boxes:
		if String(box.get("crop_id", "")) == crop_id:
			count -= int(box.get("count", 0))
	return maxi(0, count)

static func work(plot: Dictionary, prop: Dictionary, can_farm: bool, has_seed: bool, ready: bool) -> Dictionary:
	if not prop.is_empty():
		match String(prop.kind):
			"tree", "stump": return {"tool": 3, "label": "Talar"}
			"rock": return {"tool": 4, "label": "Picar roca"}
			"weed", "bush": return {"tool": 5, "label": "Despejar"}
	if not can_farm: return {}
	if not String(plot.get("crop_id", "")).is_empty():
		if bool(plot.get("wilted", false)): return {"harvest": true, "label": "Retirar planta seca"}
		if ready: return {"harvest": true, "label": "Cosechar"}
		if not bool(plot.get("watered", false)): return {"tool": 1, "label": "Regar"}
		return {}
	if plot.is_empty(): return {"tool": 5, "label": "Despejar hierba"}
	if String(plot.get("soil", "")) == "cleared": return {"tool": 0, "label": "Preparar tierra"}
	if has_seed: return {"tool": 2, "label": "Sembrar"}
	return {}
