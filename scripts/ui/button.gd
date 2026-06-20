class_name UIButton
extends Button

@export var transform_duration : float = 0.1
@export var transform_scale_multiplier : float = 1.2
@export var transform_rotation_degrees : float = 1.0

func _ready() -> void:
	offset_transform_enabled = true
	
	mouse_entered.connect(hover)
	mouse_exited.connect(end_hover)

func hover() -> void:
	var tween : Tween = create_tween()
	
	tween.tween_property(self, "offset_transform_rotation", deg_to_rad(transform_rotation_degrees), transform_duration)
	tween.tween_property(self, "offset_transform_scale", Vector2(transform_scale_multiplier, transform_scale_multiplier), transform_duration)
	
	Global.sound_manager.play("ChutterClickSound")

func end_hover() -> void:
	var tween : Tween = create_tween()

	tween.tween_property(self, "offset_transform_rotation", deg_to_rad(0.0), transform_duration)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.0,1.0), transform_duration)
