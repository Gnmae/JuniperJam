extends Node

var cake: Node2D = null

func _ready() -> void:
	await get_tree().process_frame
	
	var order := Order.get_order("order_01")
	if order == null:
		push_error("GameController: failed to load order")
		return
	
	GameSession.start_order(order)


func get_base_options() -> Array[Dictionary]:
	var order = Order.get_order("order_01")
	
	if order == null:
		push_error("No order found")
		var shuffled = Constants.CAKE_BASES.duplicate()
		shuffled.shuffle()
		return shuffled.slice(0, 3) as Array[Dictionary]
	
	var correct_id = order.cake_batter_type if "cake_batter_type" in order else ""
	
	if correct_id == "":
		push_error("Order has no cake_batter_type")
		var shuffled = Constants.CAKE_BASES.duplicate()
		shuffled.shuffle()
		return shuffled.slice(0, 3) as Array[Dictionary]
	
	# Find correct cake
	var correct: Dictionary = {}
	for base in Constants.CAKE_BASES:
		if base.id == correct_id:
			correct = base
			break
	
	if correct.is_empty():
		push_error("Correct base '" + correct_id + "' not found in CAKE_BASES")
		correct = Constants.CAKE_BASES[0] if not Constants.CAKE_BASES.is_empty() else {}
	
	# Get 2 wrong options
	var wrong: Array[Dictionary] = []
	for base in Constants.CAKE_BASES:
		if base.id != correct_id:
			wrong.append(base)
	
	wrong.shuffle()
	if wrong.size() > 2:
		wrong = wrong.slice(0, 2)
	
	# combine back and randomize order
	var final_options: Array[Dictionary] = []
	final_options.append(correct)
	final_options.append_array(wrong)
	final_options.shuffle()
	
	return final_options
	
func start_cake_minigame() -> void:
	cake = get_tree().get_first_node_in_group("cake")
	if cake:
		cake.show()
	else:
		push_warning("Cake node not found in group 'cake'")
	
	if has_node("CanvasLayer/Button"):
		$CanvasLayer/Button.hide()


func _on_cake_finished() -> void:
	print("cake_finished")
	if cake:
		GameSession.session_result.frosting_accuracy = cake.frosting_accuracy
		cake.hide()
	else:
		push_warning("Cake node not available when finished")


func _on_button_pressed() -> void:
	start_cake_minigame()
