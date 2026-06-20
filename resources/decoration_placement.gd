class_name DecorationPlacement
extends Resource

## A placed topping / decoration item (cherry, sprinkle, wafer, etc.)

@export var id: String = "cherry"         
@export var position: Vector2 = Vector2.ZERO
@export var rotation_degrees: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export var tint: Color = Color.WHITE       # Optional tint
@export var flip_h: bool = false
@export var flip_v: bool = false

func _init(p_id: String = "cherry", p_position: Vector2 = Vector2.ZERO, p_rotation: float = 0.0, p_scale: Vector2 = Vector2.ONE):
	id = p_id
	position = p_position
	rotation_degrees = p_rotation
	scale = p_scale
