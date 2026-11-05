extends RefCounted
class_name FarmMenuNavigation

signal shortcut(action: String)

const FIRST_REPEAT := 0.38
const NEXT_REPEAT := 0.12
var rows: Array = []
var controls: Array[Control] = []
var memory: Dictionary = {}
var scroll: ScrollContainer
var close_button: Button
var screen_key: String = ""
var body: Control
var _held := Vector2i.ZERO
var _held_source: String = ""
var _repeat_time: float = 0.0
var _left_axis := Vector2.ZERO
var _scroll_axis: float = 0.0
var _scroll_fraction: float = 0.0
var _blocked_direction: bool = false
var _trigger_left: bool = false
var _trigger_right: bool = false
var _accept_down: bool = false
var _accept_target: WeakRef
var _generation: int = 0
var _scroll_pending_generation: int = -1

func remember() -> void:
	if screen_key.is_empty() or not is_instance_valid(body): return
	var focused: Control = body.get_viewport().gui_get_focus_owner()
	memory[screen_key] = {"id":_id(focused), "index":controls.find(focused), "scroll":scroll.scroll_vertical}

func configure(key: String, roots: Array, content: Control, scroller: ScrollContainer, close: Button, restore: bool = true) -> void:
	_generation += 1
	screen_key = key
	body = content
	scroll = scroller
	close_button = close
	rows.clear()
	controls.clear()
	reset_input()
	_left_axis = Vector2(Input.get_action_raw_strength("ui_right")-Input.get_action_raw_strength("ui_left"), Input.get_action_raw_strength("ui_down")-Input.get_action_raw_strength("ui_up"))
	var walking := Vector2(Input.get_action_raw_strength("move_right")-Input.get_action_raw_strength("move_left"),Input.get_action_raw_strength("move_down")-Input.get_action_raw_strength("move_up"))
	_blocked_direction = _left_axis.length() > 0.35 or walking.length() > 0.35
	_trigger_left = Input.is_action_pressed("menu_page_prev")
	_trigger_right = Input.is_action_pressed("charge_tool")
	for node: Node in roots: _collect_rows(node)
	for row: Array in rows:
		for control: Control in row: controls.append(control)
	for index: int in range(controls.size()):
		var control: Control = controls[index]
		if not control.has_meta("menu_id"): control.set_meta("menu_id", "slot:%d" % index)
		control.focus_mode = Control.FOCUS_ALL
		control.focus_next = control.get_path_to(controls[(index + 1) % controls.size()])
		control.focus_previous = control.get_path_to(controls[posmod(index - 1, controls.size())])
		# Native UI traversal stays inside the modal as a keyboard fallback.
		for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: control.set_focus_neighbor(side, control.get_path())
	var target: Control = null
	var saved: Dictionary = memory.get(key, {}) if restore else {}
	for control: Control in controls:
		if _id(control) == String(saved.get("id", "")): target = control; break
	if target == null and not saved.is_empty() and not controls.is_empty():
		target = controls[clampi(int(saved.get("index", 0)), 0, controls.size()-1)]
	if target == null:
		for control: Control in controls:
			if bool(control.get_meta("menu_default", false)): target = control; break
	if target == null: target = controls[0] if not controls.is_empty() else close_button
	scroll.scroll_vertical = int(saved.get("scroll", 0))
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()
		_restore_after_layout(_generation, weakref(target), int(saved.get("scroll", 0)))

func _collect_rows(node: Node) -> void:
	if node is Control and not node.visible: return
	if node is BaseButton:
		if not node.disabled: rows.append([node])
		return
	if node is GridContainer:
		var children := node.get_children()
		for start: int in range(0,children.size(),node.columns):
			var row: Array[Control] = []
			for child: Node in children.slice(start,start+node.columns): _collect_controls(child,row)
			if not row.is_empty(): rows.append(row)
		return
	if node is HBoxContainer:
		var row: Array[Control] = []
		_collect_controls(node, row)
		if not row.is_empty(): rows.append(row)
		return
	for child: Node in node.get_children(): _collect_rows(child)

func _collect_controls(node: Node, found: Array[Control]) -> void:
	if node is Control and not node.visible: return
	if node is BaseButton:
		if not node.disabled: found.append(node)
		return
	for child: Node in node.get_children(): _collect_controls(child, found)

func _id(control: Control) -> String:
	return String(control.get_meta("menu_id", "")) if is_instance_valid(control) else ""

func reset_input() -> void:
	_held = Vector2i.ZERO
	_held_source = ""
	_left_axis = Vector2.ZERO
	_scroll_axis = 0.0
	_scroll_fraction = 0.0
	_repeat_time = 0.0
	_accept_down = false
	_accept_target = null

func handle_event(event: InputEvent) -> bool:
	if event is InputEventJoypadMotion:
		if event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
			if event.axis == JOY_AXIS_RIGHT_Y: _scroll_axis = event.axis_value if absf(event.axis_value) >= 0.3 else 0.0
			return true
		if event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
			var left: bool = event.axis == JOY_AXIS_TRIGGER_LEFT
			var was_down: bool = _trigger_left if left else _trigger_right
			if event.axis_value < 0.3:
				if left: _trigger_left = false
				else: _trigger_right = false
			elif event.axis_value >= 0.6 and not was_down:
				if left: _trigger_left = true
				else: _trigger_right = true
				shortcut.emit("trigger_prev" if left else "trigger_next")
			return true
		if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			if event.axis == JOY_AXIS_LEFT_X: _left_axis.x = event.axis_value
			else: _left_axis.y = event.axis_value
			if _blocked_direction:
				if _left_axis.length() <= 0.35: _blocked_direction = false
				return true
			var direction := Vector2i.ZERO
			if _left_axis.length() >= 0.55:
				if _held_source == "stick" and _held.y != 0 and absf(_left_axis.y) >= 0.5 and absf(_left_axis.x) <= absf(_left_axis.y)+0.2: direction.y = int(signf(_left_axis.y))
				elif _held_source == "stick" and _held.x != 0 and absf(_left_axis.x) >= 0.5 and absf(_left_axis.y) <= absf(_left_axis.x)+0.2: direction.x = int(signf(_left_axis.x))
				elif absf(_left_axis.y) >= absf(_left_axis.x): direction.y = int(signf(_left_axis.y))
				else: direction.x = int(signf(_left_axis.x))
			elif _held_source == "stick" and _left_axis.length() > 0.35: return true
			_set_held(direction, "stick")
			return true
	if event.is_action("ui_accept"):
		if event.is_action_pressed("ui_accept") and not (event is InputEventKey and event.echo):
			if not _accept_down:
				_accept_down = true
				var focused: Control = body.get_viewport().gui_get_focus_owner()
				if focused is BaseButton and not focused.disabled and (controls.has(focused) or focused == close_button): _accept_target = weakref(focused)
		elif event.is_action_released("ui_accept"):
			var target: BaseButton = _accept_target.get_ref() as BaseButton if _accept_target != null else null
			_accept_down = false
			_accept_target = null
			if is_instance_valid(target) and target.is_inside_tree() and not target.disabled and target.has_focus(): target.pressed.emit()
		return true
	if event.is_action("tool_prev") or event.is_action("tool_next"):
		if event.is_action_pressed("tool_prev") or event.is_action_pressed("tool_next"):
			if not (event is InputEventKey and event.echo): shortcut.emit("page_prev" if event.is_action_pressed("tool_prev") else "page_next")
		return true
	if event is InputEventKey:
		if event.physical_keycode in [KEY_PAGEUP, KEY_PAGEDOWN] or event.keycode in [KEY_PAGEUP, KEY_PAGEDOWN]:
			if event.pressed: shortcut.emit("jump_prev" if event.physical_keycode == KEY_PAGEUP or event.keycode == KEY_PAGEUP else "jump_next")
			return true
		if event.physical_keycode == KEY_TAB or event.keycode == KEY_TAB:
			if event.pressed and not event.echo: _linear(-1 if event.shift_pressed else 1)
			return true
	var direction := Vector2i.ZERO
	for action: String in ["ui_up", "ui_down", "ui_left", "ui_right", "move_up", "move_down", "move_left", "move_right"]:
		if event.is_action(action):
			direction = Vector2i.UP if action.ends_with("up") else (Vector2i.DOWN if action.ends_with("down") else (Vector2i.LEFT if action.ends_with("left") else Vector2i.RIGHT))
			break
	if direction != Vector2i.ZERO:
		if event.is_pressed():
			if not _blocked_direction and not (event is InputEventKey and event.echo): _set_held(direction, "button")
		elif _held == direction or _blocked_direction:
			_blocked_direction = false
			_set_held(Vector2i.ZERO, "button")
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and scroll.get_global_rect().has_point(event.position):
		scroll_by(-96.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 96.0)
		return true
	if event is InputEventMouseMotion and event.relative.length() > 2.0:
		for control: Control in controls:
			if control.get_global_rect().has_point(event.position) and (not body.is_ancestor_of(control) or scroll.get_global_rect().has_point(event.position)):
				control.grab_focus(); break
	return false

func _set_held(direction: Vector2i, source: String) -> void:
	if direction == _held and source == _held_source: return
	_held = direction
	_held_source = source
	_repeat_time = FIRST_REPEAT
	if direction != Vector2i.ZERO: move(direction)

func update(delta: float) -> void:
	if _held != Vector2i.ZERO and not _blocked_direction:
		_repeat_time -= delta
		if _repeat_time <= 0.0:
			move(_held)
			_repeat_time = NEXT_REPEAT
	if absf(_scroll_axis) >= 0.3: scroll_by(_scroll_axis * 540.0 * delta)

func move(direction: Vector2i) -> void:
	if controls.is_empty():
		if direction.y != 0: scroll_by(direction.y * 64.0)
		return
	var focused: Control = body.get_viewport().gui_get_focus_owner()
	var row_index: int = -1
	var column: int = 0
	for index: int in range(rows.size()):
		if rows[index].has(focused):
			row_index = index
			column = rows[index].find(focused)
			break
	if row_index < 0:
		_focus(controls[0]); return
	var row: Array = rows[row_index]
	if direction.x != 0:
		_focus(row[clampi(column + direction.x, 0, row.size()-1)])
	else:
		var next_row: Array = rows[clampi(row_index + direction.y, 0, rows.size()-1)]
		if row.size() == 1:
			for control: Control in next_row:
				if bool(control.get_meta("menu_active", false)):
					_focus(control); return
		var ratio: float = float(column) / float(row.size()-1) if row.size() > 1 else 1.0
		_focus(next_row[roundi(ratio * (next_row.size()-1))])

func _linear(direction: int) -> void:
	if controls.is_empty(): return
	var index: int = controls.find(body.get_viewport().gui_get_focus_owner())
	_focus(controls[posmod(index + direction, controls.size())])

func page(direction: int) -> void:
	var focused: Control = body.get_viewport().gui_get_focus_owner()
	if (focused == null or not body.is_ancestor_of(focused)) and not controls.is_empty():
		for control: Control in controls:
			if body.is_ancestor_of(control): _focus(control); return
	if not controls.is_empty() and focused != null and body.is_ancestor_of(focused):
		var items: Array[Control] = []
		for control: Control in controls:
			if body.is_ancestor_of(control): items.append(control)
		var index: int = items.find(focused)
		_focus(items[clampi(index + direction*5, 0, items.size()-1)])
	else: scroll_by(direction * scroll.size.y * 0.8)

func scroll_by(amount: float) -> void:
	_scroll_fraction += amount
	var pixels: int = int(_scroll_fraction)
	_scroll_fraction -= pixels
	scroll.scroll_vertical += pixels
	if _scroll_pending_generation != _generation:
		_scroll_pending_generation = _generation
		_reconcile_scroll_focus(_generation, amount > 0.0)

func _reconcile_scroll_focus(generation: int, downward: bool) -> void:
	if not is_instance_valid(body) or not body.is_inside_tree(): return
	await body.get_tree().process_frame
	if generation != _generation or not is_instance_valid(body) or not body.is_inside_tree(): return
	_scroll_pending_generation = -1
	var focused: Control = body.get_viewport().gui_get_focus_owner()
	if focused == null or not body.is_ancestor_of(focused): return
	if _inside_scroll(focused): return
	var visible_items: Array[Control] = []
	for control: Control in controls:
		if body.is_ancestor_of(control) and _inside_scroll(control): visible_items.append(control)
	if not visible_items.is_empty(): _focus(visible_items[0] if downward else visible_items.back())

func _restore_after_layout(generation: int, target_ref: WeakRef, scroll_position: int) -> void:
	if not is_instance_valid(body) or not body.is_inside_tree(): return
	await body.get_tree().process_frame
	if generation != _generation or not is_instance_valid(body) or not body.is_inside_tree(): return
	await body.get_tree().process_frame
	if generation != _generation or not is_instance_valid(body) or not body.is_inside_tree(): return
	var target: Control = target_ref.get_ref() as Control
	if target == null or not target.has_focus(): return
	scroll.scroll_vertical = scroll_position
	if body.is_ancestor_of(target): _reveal(target)

func _inside_scroll(control: Control) -> bool:
	var top: float = control.global_position.y - body.global_position.y
	return top >= scroll.scroll_vertical and top + control.size.y <= scroll.scroll_vertical + scroll.size.y

func _reveal(control: Control) -> void:
	# Work in content coordinates: native ensure_control_visible can double-scroll
	# before deferred container layout updates the content's global transform.
	var top: float = control.global_position.y - body.global_position.y
	var bottom: float = top + control.size.y
	if top < scroll.scroll_vertical: scroll.scroll_vertical = maxi(0,floori(top)-4)
	elif bottom > scroll.scroll_vertical + scroll.size.y: scroll.scroll_vertical = ceili(bottom-scroll.size.y)+4

func _focus(control: Control) -> void:
	control.grab_focus()
	if body.is_ancestor_of(control): _reveal(control)

func position_text() -> String:
	if not is_instance_valid(body): return ""
	var index: int = controls.find(body.get_viewport().gui_get_focus_owner())
	if index >= 0: return "%d / %d" % [index+1,controls.size()]
	var bar := scroll.get_v_scroll_bar()
	var maximum: float = maxf(0.0, bar.max_value - bar.page)
	return "Lectura · %d%%" % roundi(float(scroll.scroll_vertical)/maximum*100.0) if maximum > 0 else "Lectura"
