@tool
extends Control
class_name CakePreview

## 2.5D cylinder cake preview — single panel.
## Toggle [show_result] to switch between the goal cake (Order) and the player's result cake.
## Attach to a Control node. Set [order] in Inspector or call refresh() at runtime.

@export var order: Order = null:
	set(val):
		order = val
		_rebuild_decorations()
		queue_redraw()

## When false: shows the intended order (goal).
## When true:  shows what the player actually placed (from GameSession.session_result).
@export var show_result: bool = false:
	set(val):
		show_result = val
		_rebuild_decorations()
		queue_redraw()

@export_tool_button("Rebuild Preview") var _rebuild_btn := _rebuild_decorations

@export_group("Layout")
@export var panel_width: float  = 260.0
@export var panel_height: float = 180.0

@export_group("Cylinder Shape")
@export var ellipse_height: float = 36.0
@export var cake_layers: int      = 3

# ---------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------

func _ready() -> void:
	custom_minimum_size = Vector2(panel_width, panel_height + 28.0)
	# Defer so @export vars are set before we try to read them in editor
	call_deferred("_rebuild_decorations")
	call_deferred("queue_redraw")

func refresh() -> void:
	_rebuild_decorations()
	queue_redraw()

# ---------------------------------------------------------------
# Decoration scene instances — spawned as real child Node2Ds
# ---------------------------------------------------------------

var _deco_nodes: Array[Node2D] = []

func _rebuild_decorations() -> void:
	for n in _deco_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_deco_nodes.clear()

	if order == null:
		return

	var result: SessionResult = null
	if not Engine.is_editor_hint() and GameSession != null:
		result = GameSession.session_result

	if show_result and result != null:
		_spawn_decorations(result.top_decorations_placed, true)
		_spawn_decorations(result.side_decorations_placed, false)
	else:
		# Goal cake
		if order.top_decorations != null:
			var top_placements: Array = _get_placements(order.top_decorations)
			_spawn_decorations(top_placements, true)

		if order.side_decoration != null:
			print("[CakePreview] side_decoration: ", order.side_decoration)
			print("[CakePreview] decorations count: ", order.side_decoration.decorations.size())
			print("[CakePreview] frosting_paths count: ", order.side_decoration.frosting_paths.size())
			_spawn_decorations(order.side_decoration.decorations, false)

	queue_redraw()


func _get_placements(decs) -> Array:
	if decs == null:
		return []
	if decs.has_method("get_decorations"):
		return decs.get_decorations()
	if "decorations" in decs:
		return decs.decorations
	return []


func _spawn_decorations(placements: Array, is_top: bool) -> void:
	# Top and side decorations share the same scene structure but use different scene paths
	var scene_path: String = Constants.DECORATION_SCENES.get("top_decoration" if is_top else "side_decoration", "")
	if scene_path == "":
		push_warning("[CakePreview] Missing scene path for %s decorations" % ("top" if is_top else "side"))
		return
	var scene = load(scene_path)
	if scene == null:
		push_warning("[CakePreview] Failed to load decoration scene: %s" % scene_path)
		return

	var deco_list: Array = Constants.TOP_DECORATIONS if is_top else Constants.SIDE_DECORATIONS

	for p in placements:
		# Find matching decoration data dict by id for atlas_pos, collision_radius etc
		var deco_data: Dictionary = {}
		for d in deco_list:
			if d["id"] == p.id:
				deco_data = d
				break
		if deco_data.is_empty():
			push_warning("[CakePreview] No decoration data found for id: '%s'" % p.id)
			continue

		var node: Node2D = scene.instantiate()

		# Dummy cake ref so setup() doesn't crash — preview never calls start_fall()
		var dummy_cake := Node2D.new()
		add_child(dummy_cake)

		# add_child first so @onready vars are populated before setup() runs
		add_child(node)
		node.call("setup", deco_data, dummy_cake)

		# Kill fall processing — decoration sits at its final position immediately
		if "_falling" in node:
			node.set("_falling", false)
		node.set_process(false)
		node.set_physics_process(false)

		node.position = _top_strip_to_local(p.position) if is_top else _side_strip_to_local(p.position)
		node.rotation_degrees = p.rotation_degrees
		node.scale = Vector2.ONE * _deco_scale().x * deco_data.get("scale", Vector2.ONE).x

		_deco_nodes.append(node)
		_deco_nodes.append(dummy_cake)


func _deco_scale() -> Vector2:
	return Vector2.ONE * (panel_width / 600.0)

# ---------------------------------------------------------------
# Strip-space → local pixel coordinate helpers
# ---------------------------------------------------------------

func _cy_top() -> float: return 24.0
func _cy_bot() -> float: return panel_height - 8.0
func _cx()     -> float: return panel_width * 0.5
func _rx()     -> float: return panel_width * 0.42
func _ry()     -> float: return ellipse_height * 0.5

func _top_strip_to_local(strip_pos: Vector2) -> Vector2:
	var nx: float = clamp(strip_pos.x / 1200.0, 0.0, 1.0) * 2.0 - 1.0
	var ny: float = clamp(strip_pos.y / 300.0,  0.0, 1.0) * 2.0 - 1.0
	return Vector2(_cx() + nx * _rx() * 0.85, _cy_top() + ny * _ry() * 0.8)

func _side_strip_to_local(strip_pos: Vector2) -> Vector2:
	var nx: float = clamp(strip_pos.x / 1200.0, 0.0, 1.0)
	var ny: float = clamp(strip_pos.y / 300.0,  0.0, 1.0)
	var a: float  = lerp(-PI, 0.0, nx)
	var body_h: float = _cy_bot() - _cy_top()
	return Vector2(_cx() + cos(a) * _rx(), _cy_top() + sin(a) * _ry() + ny * body_h)

# ---------------------------------------------------------------
# Drawing — cylinder body + frosting paths
# ---------------------------------------------------------------

func _draw() -> void:
	var src: Order = order
	var base_col := Color(1.0, 0.98, 0.92)
	if src != null:
		base_col = src.cake_base_color

	var cx: float     = _cx()
	var cy_top: float = _cy_top()
	var cy_bot: float = _cy_bot()
	var rx: float     = _rx()
	var ry: float     = _ry()

	# Side face
	var side_pts := PackedVector2Array([
		Vector2(cx - rx, cy_top),
		Vector2(cx + rx, cy_top),
		Vector2(cx + rx, cy_bot),
		Vector2(cx - rx, cy_bot),
	])
	draw_colored_polygon(side_pts, base_col.darkened(0.15))

	# Layer lines
	for i in range(1, cake_layers):
		var ly: float = lerp(cy_top, cy_bot, float(i) / float(cake_layers))
		draw_line(Vector2(cx - rx, ly), Vector2(cx + rx, ly), base_col.darkened(0.28), 1.2)

	# Bottom ellipse
	_draw_ellipse(cx, cy_bot, rx, ry, base_col.darkened(0.3), true)

	# Top face
	_draw_ellipse(cx, cy_top, rx, ry, base_col.lightened(0.06), true)

	# Frosting paths — always from order's side_decoration regardless of show_result
	# (paths are part of the order spec; result shows decoration placement differences)
	if src != null and src.side_decoration != null:
		_draw_frosting_paths(cx, cy_top, cy_bot, rx, ry, src.side_decoration)

	# Outlines
	_draw_ellipse(cx, cy_bot, rx, ry, Color(0, 0, 0, 0.18), false)
	_draw_ellipse(cx, cy_top, rx, ry, Color(0, 0, 0, 0.18), false)
	draw_line(Vector2(cx - rx, cy_top), Vector2(cx - rx, cy_bot), Color(0, 0, 0, 0.18), 1.2)
	draw_line(Vector2(cx + rx, cy_top), Vector2(cx + rx, cy_bot), Color(0, 0, 0, 0.18), 1.2)

	# Label
	var font := ThemeDB.fallback_font
	var lbl := "Your Cake" if show_result else "Goal Cake"
	draw_string(font, Vector2(cx - 30, cy_top - 6), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _draw_ellipse(cx: float, cy: float, rx: float, ry: float, col: Color, filled: bool) -> void:
	var steps := 64
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var a := TAU * i / steps
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	if filled:
		draw_colored_polygon(pts, col)
	else:
		draw_polyline(pts, col, 1.2)


func _draw_frosting_paths(cx: float, cy_top: float, cy_bot: float, rx: float, ry: float, side_decs: SideDecorations) -> void:
	if side_decs.frosting_paths.is_empty():
		return
	var body_h: float = cy_bot - cy_top
	for path in side_decs.frosting_paths:
		if path.points.size() < 2:
			continue
		var mapped := PackedVector2Array()
		for pt in path.points:
			var nx: float = pt.x / 1200.0
			var ny: float = pt.y / 300.0
			var a: float  = lerp(-PI, 0.0, nx)
			mapped.append(Vector2(cx + cos(a) * rx, cy_top + sin(a) * ry + ny * body_h))
		var col := Color(path.color.r, path.color.g, path.color.b, 0.85)
		draw_polyline(mapped, col, max(1.5, path.width * 0.2))
