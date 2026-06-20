class_name DotPlacement
extends Resource

## A single decorative dot (like icing dot or candy dot, or in original testing: a candle) 
## Used inside TopDecorations.dots array.

@export var position: Vector2 = Vector2.ZERO
@export var color: Color = Color(1, 0.2, 0.2)
@export var size: float = 6.0
@export var shape: String = "circle"

func _init(p_position: Vector2 = Vector2.ZERO, p_color: Color = Color(1, 0.2, 0.2), p_size: float = 6.0, p_shape: String = "circle"):
	position = p_position
	color = p_color
	size = p_size
	shape = p_shape
