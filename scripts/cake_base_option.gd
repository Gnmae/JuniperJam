extends Node2D

signal option_selected(option_instance: Node2D)

@onready var cake_sprite: TextureButton = $CanvasLayer/CakeBaseSprite
@onready var arrow_sprite: Sprite2D = $ArrowSprite
@onready var label: Label = $CakeTypeLabel

var option_data: Dictionary = {}
var is_selected: bool = false
var _material: ShaderMaterial = null


func _ready() -> void:
	# Make material unique per instance
	if cake_sprite and cake_sprite.material:
		_material = cake_sprite.material.duplicate() as ShaderMaterial
		cake_sprite.material = _material
	
	if cake_sprite:
		cake_sprite.mouse_entered.connect(_on_hover_enter)
		cake_sprite.mouse_exited.connect(_on_hover_exit)
		cake_sprite.pressed.connect(_on_pressed)


func setup(data: Dictionary) -> void:
	option_data = data
	
	if label:
		label.text = data.get("name", data.get("id", "Unknown"))
	
	# Apply texture if available
	if data.has("texture") and data.texture is Texture2D:
		cake_sprite.texture_normal = data.texture
	
	# color modulation via the outline shader to avoid extra sprites for now
	if _material and data.has("color"):
		_material.set_shader_parameter("tint_color", data.color)
		_material.set_shader_parameter("tint_strength", 1.0)


func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visuals()


func _on_hover_enter() -> void:
	_update_visuals(true)
	Global.sound_manager.play("ChutterClickSound")


func _on_hover_exit() -> void:
	_update_visuals()


func _on_pressed() -> void:
	is_selected = not is_selected
	option_selected.emit(self)
	_update_visuals()


func _update_visuals(hover: bool = false) -> void:
	# Arrow only when selected
	arrow_sprite.visible = is_selected
	
	# Shader outline
	if _material:
		_material.set_shader_parameter("enabled", is_selected or hover)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		pass
