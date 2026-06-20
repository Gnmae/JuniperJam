class_name UIButton
extends Button

func _ready() -> void:
	offset_transform_enabled = true
	
	mouse_entered.connect(hover)
	mouse_exited.connect(end_hover)

func hover() -> void:
	var tween : Tween = create_tween()
	
	tween.tween_property(self, "offset_transform_rotation", deg_to_rad(1), 0.1)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.2, 1.2), 0.2)

func end_hover() -> void:
	var tween : Tween = create_tween()

	tween.tween_property(self, "offset_transform_rotation", deg_to_rad(0.0), 0.1)	
	tween.tween_property(self, "offset_transform_scale", Vector2(1.0,1.0), 0.2)
