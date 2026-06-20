extends Node

@onready var cake: Node2D = $Cake

<<<<<<< HEAD:scripts/game_controller.gd
=======
func start_cake_minigame() -> void:
	#pass in cake variables
	#start cake minigame
	cake.show()
	$CanvasLayer/Button.hide()
	cake.start_minigame()

>>>>>>> 80b153e9ca6e9cc3ce1d2a0df64dea82b8f3e238:game_controller.gd
func _on_cake_finished() -> void:
	print("cake_finished")
	cake.hide()

func _on_button_pressed() -> void:
	start_cake_minigame()
