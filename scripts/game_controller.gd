extends Node

@onready var cake: Node2D = $Cake

func start_cake_minigame() -> void:
	#pass in cake variables
	#start cake minigame
	cake.show()
	$CanvasLayer/Button.hide()

func _on_cake_finished() -> void:
	print("cake_finished")
	#cake.hide()
