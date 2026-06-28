class_name PathPlacement
extends Resource

@export var origin: Vector2 = Vector2.ZERO
@export var raw_points: Array[float] = []
@export_enum("red", "orange", "yellow", "green", "blue", "indigo", "violet") var color_id: String = "yellow"
@export var width: float = 4.0
@export var closed: bool = false
@export var smooth: bool = true
@export var style: String = "pipe"

func _init(p_points: PackedVector2Array = [], p_color_id: String = "yellow", p_width: float = 4.0, p_origin: Vector2 = Vector2.ZERO):
	origin = p_origin
	color_id = p_color_id
	width = p_width
	if p_points.size() > 0:
		set_points(p_points)

func set_points(pts: PackedVector2Array) -> void:
	raw_points.clear()
	for pt in pts:
		raw_points.append(pt.x)
		raw_points.append(pt.y)

func get_points() -> PackedVector2Array:
	var result := PackedVector2Array()
	var i := 0
	while i + 1 < raw_points.size():
		result.append(Vector2(raw_points[i], raw_points[i + 1]))
		i += 2
	return result

func get_color() -> Color:
	if not Constants or not Constants.FROSTING_COLORS:
		return Color.WHITE
	for entry in Constants.FROSTING_COLORS:
		if entry is Dictionary and entry.get("id") == color_id:
			return entry.get("color", Color.WHITE)
	return Color.WHITE
