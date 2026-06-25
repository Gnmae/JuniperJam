extends Control

# Scroll
@export var scroll_speed: float = 80.0
@export var strip_width: float = 1200.0
@export var strip_height: float = 300.0

# Timer
@export var decorate_time: float = 30.0

# Frosting
@export var frosting_color: Color = Color(1.0, 0.85, 0.7, 1.0)
@export var dollop_spacing: float = 16.0
@export var max_frosting_dollops: int = 300
@export var frosting_tolerance: float = 15.0

# Node refs
@onready var parallax_bg: ParallaxBackground = $CakeWindow/SubViewport/ParallaxBackground
@onready var guide_container: Node2D = $CakeWindow/SubViewport/ParallaxBackground/GuideLayer/GuideContainer
@onready var frosting_container: Node2D = $CakeWindow/SubViewport/ParallaxBackground/FrostingLayer/FrostingContainer
@onready var decoration_container: Node2D = $CakeWindow/SubViewport/ParallaxBackground/DecorationLayer/DecorationContainer
@onready var cake_window: SubViewportContainer = $CakeWindow
@onready var frosting_pointer: Sprite2D = $FrostingPointer
@onready var timer_progress_bar: ProgressBar = $UI/TimerControls/TimerProgressBar
@onready var time_label: Label = $UI/TimerControls/TimeLabel
@onready var phase_label: Label = $UI/PhaseLabel
@onready var frosting_tool_button: Button = $UI/DecorationControls/FrostingToolButton
@onready var next_button: Button = $UI/NextButton

# State
var decorate_timer: float = 0.0
var scroll_offset: float = 0.0
var is_frosting_tool_active: bool = false
var is_drawing_frosting: bool = false
var last_dollop_position: Vector2 = Vector2.ZERO
var dollop_count: int = 0
var done: bool = false

# Accuracy
var _baked_segments: Array = []
var _dollop_accuracy_sum: float = 0.0
var _dollop_accuracy_count: int = 0

func _ready() -> void:
	if frosting_pointer:
		frosting_pointer.visible = false
	if next_button:
		next_button.hide()
		next_button.pressed.connect(_on_next_pressed)
	if frosting_tool_button:
		frosting_tool_button.toggled.connect(_on_frosting_tool_toggled)

	decorate_timer = decorate_time
	timer_progress_bar.max_value = decorate_time
	timer_progress_bar.value = decorate_time
	time_label.text = str(int(decorate_time))

	_load_order()

func _load_order() -> void:
	var order = GameSession.current_order
	if order == null:
		return
	# Set cake band color from order
	var band = $CakeWindow/SubViewport/ParallaxBackground/CakeBandLayer/CakeBandA
	if band and order.cake_base_color:
		band.color = order.cake_base_color
	_setup_guide_lines(order)

func _setup_guide_lines(order: Order) -> void:
	for child in guide_container.get_children():
		child.queue_free()
	_baked_segments.clear()

	var side_decs = order.side_decoration
	if side_decs == null:
		return

	for path in side_decs.frosting_paths:
		if path.points.size() < 2:
			continue

		var world_pts := PackedVector2Array()
		for p in path.points:
			world_pts.append(path.origin + p)

		var line := Line2D.new()
		line.points = world_pts
		if path.closed and world_pts.size() > 0:
			line.add_point(world_pts[0])
		line.width = path.width
		line.default_color = Color(path.color.r, path.color.g, path.color.b, 0.4)
		line.z_index = 2
		guide_container.add_child(line)

		var segs := PackedVector2Array()
		var count := world_pts.size()
		var limit := count - 1 if not path.closed else count
		for i in range(limit):
			segs.append(world_pts[i])
			segs.append(world_pts[(i + 1) % count])
		_baked_segments.append(segs)

func _process(delta: float) -> void:
	if done:
		return

	# Auto-scroll
	scroll_offset += scroll_speed * delta
	parallax_bg.scroll_offset = Vector2(-scroll_offset, 0)

	# Timer
	decorate_timer -= delta
	decorate_timer = max(0.0, decorate_timer)
	timer_progress_bar.value = decorate_timer
	time_label.text = str(int(decorate_timer))
	_update_timer_color(decorate_timer / decorate_time)

	if decorate_timer <= 0.0:
		_finish()

	# Frosting pointer follows mouse
	if is_frosting_tool_active and frosting_pointer:
		frosting_pointer.global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if done:
		return
	if not is_frosting_tool_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_start_frosting()
		else:
			_end_frosting()
	elif event is InputEventMouseMotion and is_drawing_frosting:
		_place_frosting_dollops()

# FROSTING
func _start_frosting() -> void:
	is_drawing_frosting = true
	last_dollop_position = _mouse_to_strip_pos()
	#_place_single_dollop(last_dollop_position)

func _end_frosting() -> void:
	is_drawing_frosting = false

func _place_frosting_dollops() -> void:
	if not is_drawing_frosting or dollop_count >= max_frosting_dollops:
		return
	var current_pos := _mouse_to_strip_pos()
	var delta := _least_distance_between(last_dollop_position, current_pos)
	var distance = delta.length()
	if distance >= dollop_spacing:
		var direction := delta.normalized()
		var steps := int(distance / dollop_spacing)
		for i in range(1, steps + 1):
			if dollop_count >= max_frosting_dollops:
				break
			var pos := last_dollop_position + direction * dollop_spacing * i
			pos.x = fposmod(pos.x, strip_width)
			_place_single_dollop(last_dollop_position + direction * dollop_spacing * i)
		var last_pos := last_dollop_position + direction * dollop_spacing * steps
		last_pos.x = fposmod(last_pos.x, strip_width)
		last_dollop_position = last_pos

func _least_distance_between(a: Vector2, b: Vector2) -> Vector2:
	var dx := b.x - a.x
	if dx > strip_width * 0.5:
		dx -= strip_width
	elif dx < -strip_width * 0.5:
		dx += strip_width
	return Vector2(dx, b.y-a.y)

func _place_single_dollop(pos: Vector2) -> void:
	var scene_path = Constants.DECORATION_SCENES.frosting_dollop
	if scene_path == "":
		return
	var scene = load(scene_path)
	if not scene:
		return
	var dollop = scene.instantiate()
	frosting_container.add_child(dollop)
	dollop.position = pos
	dollop.modulate = frosting_color
	dollop_count += 1
	_record_dollop_accuracy(pos)

# Converts mouse position into strip-local coordinates accounting for scroll
func _mouse_to_strip_pos() -> Vector2:
	var local := cake_window.get_local_mouse_position()
	# Scale from container size to viewport size
	var scale_x := strip_width / cake_window.size.x
	var scale_y := strip_height / cake_window.size.y
	var viewport_pos := Vector2(local.x * scale_x, local.y * scale_y)
	# Add scroll offset and wrap within strip width
	var world_x := fmod(viewport_pos.x + scroll_offset, strip_width)
	if world_x < 0:
		world_x += strip_width
	return Vector2(world_x, viewport_pos.y)

# ACCURACY
func _record_dollop_accuracy(pos: Vector2) -> void:
	if _baked_segments.is_empty():
		return
	var dist := _distance_to_all_guides(pos)
	var score: float = clamp(1.0 - dist / frosting_tolerance, 0.0, 1.0)
	_dollop_accuracy_sum += score
	_dollop_accuracy_count += 1

func _distance_to_all_guides(pos: Vector2) -> float:
	var best := INF
	for segs: PackedVector2Array in _baked_segments:
		var i := 0
		while i + 1 < segs.size():
			best = min(best, _point_segment_distance(pos, segs[i], segs[i + 1]))
			i += 2
	return best

func _point_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.dot(ab)
	if len_sq == 0.0:
		return p.distance_to(a)
	var t: float = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

# FINISH
func _finish() -> void:
	done = true
	is_drawing_frosting = false
	var accuracy := 0.0
	if _dollop_accuracy_count > 0:
		accuracy = _dollop_accuracy_sum / float(_dollop_accuracy_count)
	print("Side frosting accuracy: ", accuracy)
	if GameSession.session_result:
		GameSession.session_result.side_frosting_accuracy = accuracy
	phase_label.text = "Done!"
	if next_button:
		next_button.show()

func _on_next_pressed() -> void:
	Global.scene_manager.change_world_2d_scene("")
	Global.scene_manager.change_ui_scene(Constants.SCENE_PATHS.order_ticket)

func _on_frosting_tool_toggled(pressed: bool) -> void:
	is_frosting_tool_active = pressed
	if frosting_pointer:
		frosting_pointer.visible = pressed
	if not pressed:
		_end_frosting()

func _update_timer_color(progress: float) -> void:
	var color: Color
	if progress > 0.6:
		color = Color(0.2, 0.8, 0.3)
	elif progress > 0.3:
		color = Color(1.0, 0.85, 0.2)
	else:
		color = Color(0.9, 0.2, 0.2)
	timer_progress_bar.get("theme_override_styles/fill").bg_color = color
