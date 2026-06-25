extends Node2D

@onready var confirm_button: Button = $ConfirmControl/ConfirmButton
@onready var marker_left: Marker2D = $MarkerLeft
@onready var marker_center: Marker2D = $MarkerCenter
@onready var marker_right: Marker2D = $MarkerRight

var cake_base_option_scene: PackedScene = load(Constants.SCENE_PATHS["cake_base_option"]) as PackedScene

var option_instances: Array[Node2D] = []
var selected_option: Node2D = null

func _ready() -> void:
	confirm_button.disabled = true
	_load_base_options()

func _load_base_options() -> void:
	var options_data: Array[Dictionary] = []
	
	if GameController and GameController.has_method("get_base_options"):
		options_data = GameController.get_base_options()
	else:
		push_error("GameController missing get_base_options()")
		if Constants and Constants.has("CAKE_BASES"):
			var shuffled = Constants.CAKE_BASES.duplicate()
			shuffled.shuffle()
			options_data = shuffled.slice(0, 3) as Array[Dictionary]
	
	if options_data.size() < 3:
		push_error("Expected 3 options")
		return
	
	var markers: Array[Marker2D] = [marker_left, marker_center, marker_right]
	
	for i in range(min(3, options_data.size())):
		var data: Dictionary = options_data[i]
		var option_instance: Node2D = cake_base_option_scene.instantiate() as Node2D
		
		if option_instance == null: continue
		
		add_child(option_instance)
		option_instance.global_position = markers[i].global_position
		
		var canvas := option_instance.get_node_or_null("CanvasLayer") as CanvasLayer
		if canvas:
			canvas.follow_viewport_enabled = false
			canvas.offset = markers[i].global_position
		
		if option_instance.has_method("setup"):
			option_instance.setup(data)
		
		if option_instance.has_signal("option_selected"):
			if not option_instance.option_selected.is_connected(_on_option_selected):
				option_instance.option_selected.connect(_on_option_selected)
				
		option_instances.append(option_instance)

func _on_option_selected(option_instance: Node2D) -> void:
	if option_instance == null: return
	
	for inst in option_instances:
		if inst and inst.has_method("set_selected"):
			inst.set_selected(inst == option_instance)
	
	selected_option = option_instance
	
	confirm_button.disabled = false

func _on_confirm_button_pressed() -> void:
	if selected_option == null:
		push_warning("No option selected")
		return
	
	var data: Dictionary = selected_option.option_data if "option_data" in selected_option else {}
	print("Saving cake_base_data: ", data)  # confirm it has color
	
	GameSession.cake_base_data = data 
	
	if GameSession and GameSession.session_result:
		GameSession.session_result.set("cake_base_id", data.get("id", ""))

	Global.scene_manager.change_world_2d_scene("")
	Global.scene_manager.change_ui_scene(Constants.SCENE_PATHS.spin_speed)
