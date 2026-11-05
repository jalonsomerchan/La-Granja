extends Button
class_name BackpackSlot

signal item_dropped(source: int, destination: int, item: String)

var slot_index: int = -1
var item_id: String = ""
var drag_owner_id: int = 0
var drag_enabled: bool = true
var item_name: String = ""
var amount: int = 0
var drop_validator: Callable

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty() or not drag_enabled: return null
	var preview := PanelContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = "%s ×%d" % [item_name,amount]
	label.add_theme_font_size_override("font_size",20)
	preview.add_child(label)
	set_drag_preview(preview)
	return {"type":"farm_backpack_item","owner":drag_owner_id,"source":slot_index,"item":item_id}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("type","") != "farm_backpack_item" or int(data.get("owner",-1)) != drag_owner_id: return false
	return drop_validator.is_valid() and bool(drop_validator.call(int(data.get("source",-1)),slot_index,String(data.get("item",""))))

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position,data): item_dropped.emit(int(data.source),slot_index,String(data.item))
