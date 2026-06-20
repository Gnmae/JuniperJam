extends Control


func _on_play_button_pressed() -> void:
	Global.scene_manager.change_world_2d_scene("uid://cyo7hmcnjxr4o") # uid of opening scene res://opening_scene/opening_scene.tscn
	Global.scene_manager.change_ui_scene("")

func _on_options_button_pressed() -> void:
	%MainMenuUI.hide()
	%OptionsUI.show()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_options_return_button_pressed() -> void:
	%MainMenuUI.show()
	%OptionsUI.hide()
