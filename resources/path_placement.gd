class_name PathPlacement
extends Resource

## A frosting path / piped line / swirl on the cake.
## points are stored **relative** to `origin`.
## In game code:  world_pos = origin + point
## This makes it easy to move/rotate/scale whole paths together.

@export var origin: Vector2 = Vector2.ZERO
@export var points: PackedVector2Array = []
@export var color: Color = Color(1, 1, 1)
@export var width: float = 4.0
@export var closed: bool = false          # If true, connect last point back to first
@export var smooth: bool = true           # Hint for game to use curve interpolation
@export var style: String = "pipe"        # "pipe", "zigzag", "swirl", "heart_outline"

func _init(p_points: PackedVector2Array = [], p_color: Color = Color.WHITE, p_width: float = 4.0, p_origin: Vector2 = Vector2.ZERO):
	origin = p_origin
	points = p_points
	color = p_color
	width = p_width
