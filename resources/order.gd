class_name Order
extends Resource

const DotPlacement = preload("res://resources/dot_placement.gd")
const PathPlacement = preload("res://resources/path_placement.gd")
const DecorationPlacement = preload("res://resources/decoration_placement.gd")
const TopDecorations = preload("res://resources/top_decorations.gd")

@export var order_id: String = "order_001"
@export var customer_name: String = "Customer"
@export var cake_batter_type: String = "vanilla"
@export var cake_base_color: Color = Color(1.0, 0.98, 0.92)
@export var top_decorations: TopDecorations = null
@export var frosting_paths: Array[PathPlacement] = []
@export var time_limit_seconds: float = 60.0

# default/placeholder names here
func _init(p_id: String = "order_01", p_customer: String = "Customer"):
	order_id = p_id
	customer_name = p_customer
	if top_decorations == null:
		top_decorations = TopDecorations.new()

func get_top_decorations() -> TopDecorations:
	if top_decorations == null:
		top_decorations = TopDecorations.new()
	return top_decorations

func get_frosting_paths() -> Array[PathPlacement]:
	return frosting_paths

func has_frosting_paths() -> bool:
	return frosting_paths.size() > 0

# ORDER LOADING
static func get_order(order_id: String = "order_001") -> Order:
	var path = Constants.ORDERS.get(order_id)

	if path and ResourceLoader.exists(path):
		return load(path)
	else:
		push_error("Order not found: " + str(order_id))
		return null
