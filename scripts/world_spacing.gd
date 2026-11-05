extends RefCounted

# Spatial bins keep repairing a crowded old save fast. Rectangles still decide
# overlap; sharing a bin does not prevent two objects from fitting beside it.
const BIN_SIZE := 64.0
var bins: Dictionary = {}

func occupy(bounds: Rect2) -> void:
	for y: int in range(floori(bounds.position.y / BIN_SIZE), ceili(bounds.end.y / BIN_SIZE)):
		for x: int in range(floori(bounds.position.x / BIN_SIZE), ceili(bounds.end.x / BIN_SIZE)):
			var key := Vector2i(x,y)
			if not bins.has(key): bins[key] = []
			bins[key].append(bounds)

func can_fit(bounds: Rect2) -> bool:
	for y: int in range(floori(bounds.position.y / BIN_SIZE), ceili(bounds.end.y / BIN_SIZE)):
		for x: int in range(floori(bounds.position.x / BIN_SIZE), ceili(bounds.end.x / BIN_SIZE)):
			for other: Rect2 in bins.get(Vector2i(x,y), []):
				if bounds.intersects(other): return false
	return true
