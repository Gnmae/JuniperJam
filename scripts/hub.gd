extends Control

@onready var total_orders_label: Label = %TotalOrdersLabel
@onready var total_score_label: Label = %TotalScoreLabel
@onready var high_score_label: Label = %HighScoreLabel
@onready var last_orders_container: VBoxContainer = %LastOrdersContainer
@onready var orders_list_container: VBoxContainer = %OrdersListContainer
@onready var preview_panel: PanelContainer = %PreviewPanel
@onready var preview_order_id: Label = %PreviewOrderId
@onready var preview_customer: Label = %PreviewCustomer
@onready var preview_time: Label = %PreviewTime
@onready var preview_batter: Label = %PreviewBatter
@onready var start_order_button: Button = %StartOrderButton
@onready var close_preview_button: Button = %ClosePreviewButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton

var selected_order: Order = null

func _ready() -> void:
	print(">>> HUB _ready() called")
	preview_panel.hide()
	_populate_stats()
	_populate_last_orders()
	_populate_orders_list()
	print(">>> HUB ready finished")

func _populate_stats() -> void:
	print(">>> Populating stats...")
	total_orders_label.text = "Orders Completed: " + str(GameSession.get_total_orders())
	total_score_label.text = "Total Score: " + str(GameSession.get_total_score())
	high_score_label.text = "High Score: " + str(GameSession.get_high_score())
	print("Stats populated")

func _populate_last_orders() -> void:
	for child in last_orders_container.get_children():
		child.queue_free()

	var last_orders = GameSession.get_last_orders()
	print("Last orders count: ", last_orders.size())

	if last_orders.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No orders completed yet."
		last_orders_container.add_child(empty_label)
		return

	var reversed_orders = last_orders.duplicate()
	reversed_orders.reverse()

	for record in reversed_orders:
		var row = HBoxContainer.new()
		var order_label = Label.new()
		order_label.text = record["order_id"]
		order_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(order_label)

		var score_label = Label.new()
		score_label.text = str(record["score"]) + " pts"
		row.add_child(score_label)

		last_orders_container.add_child(row)

func _populate_orders_list() -> void:
	for child in orders_list_container.get_children():
		child.queue_free()

	for order_id in Constants.ORDERS.keys():
		var order = Order.get_order(order_id)
		if order == null:
			continue

		var btn = Button.new()
		btn.text = "%s — %s (%.0fs)" % [order.order_id, order.customer_name, order.time_limit_seconds]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _on_order_selected(order))
		orders_list_container.add_child(btn)

	print("Orders list populated. Count: ", orders_list_container.get_child_count())

func _on_order_selected(order: Order) -> void:
	selected_order = order
	preview_order_id.text = "Order: " + order.order_id
	preview_customer.text = "Customer: " + order.customer_name
	preview_batter.text = "Batter: " + order.cake_batter_type
	preview_time.text = "Time Limit: %.0f seconds" % order.time_limit_seconds
	preview_panel.show()

func _on_start_order_button_pressed() -> void:
	if selected_order == null:
		print("No order selected")
		return

	print(">>> Starting order: ", selected_order.order_id)
	preview_panel.hide()
	GameSession.start_order(selected_order)
	Global.scene_manager.change_world_2d_scene("")
	Global.scene_manager.change_ui_scene(Constants.SCENE_PATHS.order_ticket)

func _on_close_preview_button_pressed() -> void:
	preview_panel.hide()
	selected_order = null

func _on_main_menu_button_pressed() -> void:
	Global.scene_manager.change_world_2d_scene("")
	Global.scene_manager.change_ui_scene(Constants.SCENE_PATHS.main_menu)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func show_order_results() -> void:
	preview_panel.hide()

	var result = GameSession.session_result

	if result == null:
		print("[Hub] ERROR: session_result is NULL")
		%OrderResults.show()
		return

	if result.order == null:
		print("[Hub] ERROR: result.order is NULL")
		%OrderResults.show()
		return

	%OrderResults.show()

	%OrderResults/MarginContainer/VBoxContainer/PreviewOrderId.text = "Order: " + result.order.order_id
	%OrderResults/MarginContainer/VBoxContainer/PreviewCustomer.text = "Customer: " + result.order.customer_name

	%OrderResults/MarginContainer/VBoxContainer/TopScore/HBoxContainer/TopFrosting.text = "Frosting: %.0f%%" % (result.frosting_accuracy * 100)
	%OrderResults/MarginContainer/VBoxContainer/TopScore/HBoxContainer/TopDecorations.text = "Decorations: %.0f%%" % (result.decoration_accuracy * 100)

	%OrderResults/MarginContainer/VBoxContainer/SideScore/HBoxContainer/SideFrosting.text = "Frosting: %.0f%%" % (result.side_frosting_accuracy * 100)
	%OrderResults/MarginContainer/VBoxContainer/SideScore/HBoxContainer/SideDecorations.text = "Decorations: %.0f%%" % (result.side_decoration_accuracy * 100)
