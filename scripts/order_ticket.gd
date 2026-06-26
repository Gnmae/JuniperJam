extends Control

@onready var order_header_label: Label = $NinePatchRect/VBoxContainer/OrderHeaderLabel
@onready var cake_type_label: Label = $NinePatchRect/VBoxContainer/CakeTypeLabel
@onready var frosting_label: Label = $NinePatchRect/VBoxContainer/FrostingLabel
@onready var decorations_label: Label = $NinePatchRect/VBoxContainer/DecorationsLabel
@onready var time_limit_label: Label = $NinePatchRect/VBoxContainer/TimeLimitLabel

func _ready() -> void:
	$NinePatchRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$NinePatchRect/VBoxContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$NextButton.pressed.connect(_on_next_button_pressed)

	var order := GameSession.current_order
	if order == null:
		push_error("OrderTicket: no current_order set in GameSession")
		return
	order_header_label.text = "Order for %s" % order.customer_name
	cake_type_label.text = "Cake: %s" % order.cake_batter_type.capitalize()
	var top := order.get_top_decorations()
	if top:
		frosting_label.text = "Frosting: %s %s" % [top.frosting_type.capitalize(), top.frosting_style.capitalize()]
		if top.decorations.is_empty():
			decorations_label.text = "Decorations: none"
		else:
			var dec_names: Array = []
			for dec in top.decorations:
				dec_names.append(dec.id.capitalize())
			decorations_label.text = "Decorations: %s" % ", ".join(dec_names)
	else:
		frosting_label.text = "Frosting: none"
		decorations_label.text = "Decorations: none"
	time_limit_label.text = "Time limit: %ds" % int(order.time_limit_seconds)

func _on_next_button_pressed() -> void:
	Global.scene_manager.change_ui_scene("")
	Global.scene_manager.change_world_2d_scene(Constants.SCENE_PATHS.cake_base_selection)
