class_name PathPlacement
extends Resource

## A frosting path / piped line / swirl on the cake.
## points are stored **relative** to `origin`.
## In game code:  world_pos = origin + point
## This makes it easy to move/rotate/scale whole paths together.

@export var origin: Vector2 = Vector2.ZERO
@export var points: PackedVector2Array = []
@export var width: float = 4.0
@export var closed: bool = false          # If true, connect last point back to first
@export var smooth: bool = true           # Hint for game to use curve interpolation
@export var style: String = "pipe"        # "pipe", "zigzag", "swirl", "heart_outline"

## ID into Constants.FROSTING_COLORS — e.g. "red", "orange", "yellow" ...
@export_enum("red", "orange", "yellow", "green", "blue", "indigo", "violet") \
	var color_id: String = "red"

## Resolved Color — use this in game code instead of a raw Color field.
var color: Color:
	get:
		for entry in Constants.FROSTING_COLORS:
			if entry["id"] == color_id:
				return entry["color"]
		return Color.WHITE

func _init(p_points: PackedVector2Array = [], p_color_id: String = "red", p_width: float = 4.0, p_origin: Vector2 = Vector2.ZERO):
	origin   = p_origin
	points   = p_points
	color_id = p_color_id
	width    = p_width
