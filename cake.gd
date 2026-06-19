extends Node2D

@export var spin_time : float = 5.0
@export var decorate_time : float = 20.0
@export var spin_speed_multiplier : float = 0.1

@onready var sprite : Sprite2D = $Sprite2D

var last_mouse_pos : Vector2 = Vector2.ZERO
var last_rotation : float = 0.0

var state : STATE = STATE.INITIAL

enum STATE {INITIAL, SPIN, DECORATE, DONE}

signal finished

func _ready() -> void:
	state = STATE.SPIN
	spin_enter()

func _process(delta: float) -> void:
	if state == STATE.SPIN:
		spin_update(delta)
	elif state == STATE.DECORATE:
		decorate_update(delta)


func spin_enter() -> void:
	await get_tree().create_timer(spin_time).timeout
	state = STATE.DECORATE
	decorate_enter()

func decorate_enter() -> void:
	await get_tree().create_timer(decorate_time).timeout
	print("decorate_done")
	state = STATE.DONE
	done_enter()

func done_enter() -> void:
	finished.emit()

func spin_update(delta : float) -> void:
	var current_mouse_pos = get_global_mouse_position()
	var mouse_movement = current_mouse_pos - last_mouse_pos
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if mouse_movement.y > 0.0:
			sprite.rotation_speed += mouse_movement.y * spin_speed_multiplier
	last_rotation = sprite.rotation_degrees
	last_mouse_pos = current_mouse_pos

func decorate_update(delta : float) -> void:
	var current_mouse_pos = get_global_mouse_position()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pass
		#print("decor")
