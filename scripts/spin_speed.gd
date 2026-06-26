extends Control

@onready var spin_label: Label = $"VBoxContainer/Spin Label"
@onready var spin_button: Button = $"VBoxContainer/Spin Button"
@onready var next_button: Button = $VBoxContainer/NextButton

func _ready() -> void:
	spin_button.pressed.connect(_on_spin_pressed)
	next_button.pressed.connect(_on_next_pressed)

func _on_spin_pressed() -> void:
	var result: float = snappedf(randf_range(1.0, 10.0), 0.01)
	GameSession.session_result.spin_speed = result
	spin_label.text = "Speed: %.2f" % result
	spin_button.hide()
	next_button.show()

func _on_next_pressed() -> void:
	Global.scene_manager.change_ui_scene("")
	Global.scene_manager.change_world_2d_scene(Constants.SCENE_PATHS.top_decotation)
	#get_tree().change_scene_to_file(Constants.SCENE_PATHS.top_decotation)
