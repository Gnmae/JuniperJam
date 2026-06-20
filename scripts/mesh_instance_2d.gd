extends Sprite2D

var previous_rotation : float = 0.0
var rotation_speed : float = 10.0

func _process(delta: float) -> void:
	rotate(deg_to_rad(rotation_speed*delta))
