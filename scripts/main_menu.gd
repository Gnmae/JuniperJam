extends Control

@export var transition_time : float = 0.1

func _on_play_button_pressed() -> void:
	await get_tree().create_timer(transition_time).timeout
	Global.scene_manager.change_world_2d_scene("uid://cyo7hmcnjxr4o") # uid of opening scene res://opening_scene/opening_scene.tscn
	Global.scene_manager.change_ui_scene("")

func _on_options_button_pressed() -> void:
	await get_tree().create_timer(transition_time).timeout
	%MainMenuUI.hide()
	%OptionsUI.show()

func _on_quit_button_pressed() -> void:
	await get_tree().create_timer(transition_time).timeout
	get_tree().quit()

func _on_options_return_button_pressed() -> void:
	await get_tree().create_timer(transition_time).timeout
	%MainMenuUI.show()
	%OptionsUI.hide()
