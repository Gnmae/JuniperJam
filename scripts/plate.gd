extends Sprite2D
@onready var plate_area_2d: Area2D = $"../PlateArea2D"
@onready var sprite: Sprite2D = $"."
@onready var root: Node2D = $".."
@onready var hand_sprite: Sprite2D = $"../PlateArea2D/HandSprite"

var is_dragging : bool = false
var mouse_click : bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				is_dragging = true
				hand_sprite.visible = true
			else:
				is_dragging = false
				mouse_click = false
				hand_sprite.visible = false
				sprite.reparent(root)
	if is_dragging and mouse_click:
		plate_area_2d.look_at(get_global_mouse_position())
		sprite.reparent(plate_area_2d)

func _on_plate_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				mouse_click = true
