extends RefCounted
class_name BackpackLayout

const COLUMNS := 6
const ROWS := 4
const PAGE_SIZE := COLUMNS * ROWS
const SCHEMA := 2

static func synchronize(saved_slots: Array, inventory: Dictionary) -> Array[String]:
	var slots: Array[String] = []
	var seen: Dictionary = {}
	for value: Variant in saved_slots:
		var item: String = String(value)
		if item.is_empty() or int(inventory.get(item,0)) <= 0 or seen.has(item): slots.append("")
		else:
			slots.append(item)
			seen[item] = true
	for value: Variant in inventory:
		var item: String = String(value)
		if item.is_empty() or int(inventory[item]) <= 0 or seen.has(item): continue
		var free: int = slots.find("")
		if free < 0: slots.append(item)
		else: slots[free] = item
		seen[item] = true
	while not slots.is_empty() and slots.back().is_empty(): slots.pop_back()
	var capacity: int = maxi(PAGE_SIZE, ceili(slots.size()/float(PAGE_SIZE))*PAGE_SIZE)
	while slots.size() < capacity: slots.append("")
	if not slots.has(""):
		for index: int in range(PAGE_SIZE): slots.append("")
	return slots

static func swap(slots: Array[String], source: int, destination: int) -> bool:
	if source < 0 or destination < 0 or source >= slots.size() or destination >= slots.size() or slots[source].is_empty(): return false
	var item: String = slots[destination]
	slots[destination] = slots[source]
	slots[source] = item
	return true

static func migrate(data: Dictionary, unit_price: Callable) -> Dictionary:
	# Old physical crates were already included in inventory. Truck cargo and
	# hand produce were separate. Never count the same crate contents twice.
	var result: Dictionary = data.duplicate(true)
	var stock: Dictionary = result.get("inventory", {}).duplicate(true)
	var quality: Dictionary = result.get("quality_stock", {}).duplicate(true)
	var adjustments: Dictionary = result.get("inventory_value_adjustments", {}).duplicate(true)
	if int(result.get("inventory_schema",0)) < SCHEMA:
		var hand_id: String = String(result.get("carried_crop_id",""))
		var hand_count: int = maxi(0,int(result.get("carried_crop_count",0)))
		if not hand_id.is_empty() and hand_count > 0:
			_add(stock,quality,hand_id,hand_count,String(result.get("carried_quality","normal")))
		var boxed: Dictionary = {}
		for box: Dictionary in result.get("produce_boxes",[]):
			var item: String = String(box.get("crop_id",""))
			if not item.is_empty(): boxed[item] = int(boxed.get(item,0)) + maxi(0,int(box.get("count",0)))
		for item: String in boxed:
			var missing: int = maxi(0,int(boxed[item])-int(stock.get(item,0)))
			if missing > 0: _add(stock,quality,item,missing,"normal")
		for cargo: Dictionary in result.get("truck_cargo",[]):
			var item: String = String(cargo.get("crop_id",""))
			var count: int = maxi(0,int(cargo.get("count",0)))
			if item.is_empty() or count <= 0: continue
			var price: int = maxi(0,int(unit_price.call(item)))
			_add(stock,quality,item,count,"normal")
			var value: int = int(cargo.get("value",price*count))
			adjustments[item] = int(adjustments.get(item,0)) + value-price*count
	for obsolete: String in ["produce_boxes","produce_box_tiles","truck_cargo","carried_crop_id","carried_crop_count","carried_quality"]: result.erase(obsolete)
	result["inventory"] = stock
	result["quality_stock"] = quality
	result["inventory_value_adjustments"] = adjustments
	result["inventory_schema"] = SCHEMA
	result["inventory_slots"] = synchronize(result.get("inventory_slots",[]),stock)
	return result

static func _add(stock: Dictionary, quality: Dictionary, item: String, count: int, tier: String) -> void:
	var old_count: int = int(stock.get(item,0))
	var tiers: Dictionary = quality.get(item,{}).duplicate(true)
	var recorded: int = 0
	for value: Variant in tiers.values(): recorded += maxi(0,int(value))
	if recorded < old_count: tiers["normal"] = int(tiers.get("normal",0)) + old_count-recorded
	stock[item] = old_count+count
	tiers[tier] = int(tiers.get(tier,0)) + count
	quality[item] = tiers
