extends Control

@onready var order_header_label: Label = $Container/VBoxContainer/Panel/VBoxContainer/OrderHeaderLabel
@onready var cake_type_label: Label = $Container/VBoxContainer/Panel/VBoxContainer/CakeTypeLabel
@onready var frosting_label: Label = $Container/VBoxContainer/Panel/VBoxContainer/FrostingLabel
@onready var decorations_label: Label = $Container/VBoxContainer/Panel/VBoxContainer/DecorationsLabel
@onready var time_limit_label: Label = $Container/VBoxContainer/Panel/VBoxContainer/TimeLimitLabel
@onready var cake_preview: CakePreview = $Container/VBoxContainer/Panel/VBoxContainer/Control

func _ready() -> void:
	var order := GameSession.current_order
	if order == null:
		push_error("OrderTicket: no current_order set in GameSession")
		print("Using first order in Constants as placeholder...")
		var placeholder_path = Constants.ORDERS.values()[0]
		order = load(placeholder_path)
		if order == null:
			push_error("OrderTicket: failed to load placeholder order")
			return

	# Assign to preview — node is in tree by now so _rebuild_decorations will work
	cake_preview.order = order

	order_header_label.text = "Order for %s" % order.customer_name
	cake_type_label.text = "Cake Batter:\n%s" % order.cake_batter_type.capitalize()
	var top := order.get_top_decorations()
	if top:
		frosting_label.text = "Frosting: %s" % [top.frosting_type.capitalize()]
		if top.decorations.is_empty():
			decorations_label.text = "Decorations:\nnone"
		else:
			var counts: Dictionary = {}
			for dec in top.decorations:
				var key = dec.id.capitalize()
				counts[key] = counts.get(key, 0) + 1
			var dec_names: Array = []
			for item in counts:
				if counts[item] > 1:
					dec_names.append("%s x%d" % [item, counts[item]])
				else:
					dec_names.append(item)
			decorations_label.text = "Decorations:\n%s" % ", ".join(dec_names)
	else:
		frosting_label.text = "Frosting:\nnone"
		decorations_label.text = "Decorations:\nnone"
	time_limit_label.text = "Time limit:\n%ds" % int(order.time_limit_seconds)

func _on_next_button_pressed() -> void:
	Global.scene_manager.change_ui_scene("")
	Global.scene_manager.change_world_2d_scene(Constants.SCENE_PATHS.cake_base_selection)
