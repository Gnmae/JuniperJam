extends Control

@export var scroll_speed: float = 80.0
@export var strip_width: float = 1200.0
@export var strip_height: float = 300.0
@export var decorate_time: float = 30.0
@export var frosting_color: Color = Color(1.0, 0.85, 0.7, 1.0)
@export var dollop_spacing: float = 16.0
@export var max_frosting_dollops: int = 300
@export var frosting_tolerance: float = 15.0

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

var decorate_timer: float = 0.0
var scroll_offset: float = 0.0
var is_frosting_tool_active: bool = false
var is_drawing_frosting: bool = false
var last_dollop_position: Vector2 = Vector2.ZERO
var dollop_count: int = 0
var done: bool = false
var _baked_segments: Array = []
var _dollop_accuracy_sum: float = 0.0
var _dollop_accuracy_count: int = 0

# Side decoration scoring
var decoration_accuracy: float = 0.0
var _side_decoration_score_sum: float = 0.0
var _side_decoration_score_count: int = 0

func _ready() -> void:
	_load_order()
	if frosting_pointer:
		frosting_pointer.visible = false
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if frosting_tool_button:
		frosting_tool_button.toggled.connect(_on_frosting_tool_toggled)

	#decorate_timer = decorate_time
	timer_progress_bar.max_value = decorate_time
	timer_progress_bar.value = decorate_time
	time_label.text = str(int(decorate_time))
	
	Global.sound_manager.play("TickingSound")

func _load_order() -> void:
	var order = GameSession.current_order
	if order == null:
		return

	var band = $CakeWindow/SubViewport/ParallaxBackground/CakeBandLayer/CakeBandA
	if band and order.cake_base_color:
		band.color = order.cake_base_color
	
	decorate_time = order.time_limit_seconds
	decorate_timer = order.time_left
	_setup_guide_lines(order)
	spawn_side_decoration_targets()

func spawn_side_decoration_targets() -> void:
	for child in decoration_container.get_children():
		if child.has_meta("is_target"):
			child.queue_free()

	var order = GameSession.current_order
	if order == null:
		return

	var side_decs = order.side_decoration
	if side_decs == null:
		return

	var placements: Array = []
	if "decorations" in side_decs:
		placements = side_decs.decorations
	elif side_decs.has_method("get_decorations"):
		placements = side_decs.get_decorations()

	if placements.is_empty():
		return

	var target_scene_path: String = Constants.SCENE_PATHS.get("decoration_target", "")
	if target_scene_path == "":
		push_error("Missing 'decoration_target' in Constants.SCENE_PATHS")
		return

	for placement in placements:
		if placement == null or placement.id == "":
			continue

		var target: DecorationTarget = load(target_scene_path).instantiate()
		decoration_container.add_child(target)
		target.position = placement.position
		target.rotation_degrees = placement.rotation_degrees
		target.scale = placement.scale

		if target.has_method("setup"):
			target.setup(placement)

		target.set_meta("decoration_id", placement.id)
		target.set_meta("is_target", true)

func _setup_guide_lines(order: Order) -> void:
	print(">>> _setup_guide_lines() called")

	for child in guide_container.get_children():
		child.queue_free()
	_baked_segments.clear()

	var side_decs = order.side_decoration
	print("side_decs = ", side_decs)

	if side_decs == null:
		print("!!! side_decs is NULL - exiting")
		return

	print("frosting_paths count = ", side_decs.frosting_paths.size())

	var paths_added := 0

	for path in side_decs.frosting_paths:
		print("  -> Processing path: ", path)
		print("     points.size() = ", path.points.size())

		if path.points.size() < 2:
			print("     SKIPPED: less than 2 points")
			continue

		var line := Line2D.new()
		line.points = path.points
		if path.closed and path.points.size() > 0:
			line.add_point(path.points[0])
		line.width = path.width
		line.default_color = Color(path.color.r, path.color.g, path.color.b, 0.45)
		line.z_index = 2
		guide_container.add_child(line)

		var segs := PackedVector2Array()
		var count: int = path.points.size()
		var limit: int = count - 1 if not path.closed else count
		for i in range(limit):
			segs.append(path.points[i])
			segs.append(path.points[(i + 1) % count])
		_baked_segments.append(segs)

		paths_added += 1
		print("ADDED successfully")

	print("Finished _setup_guide_lines(). Paths added: ", paths_added)
	print("baked_segments count: ", _baked_segments.size())
func _create_sine_wave_guide(y_center: float = 150.0, amplitude: float = 30.0, frequency: float = 0.02, color: Color = Color(1, 0, 0, 0.5), width: float = 6.0, segments: int = 400) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.z_index = 2
	for i in range(segments + 1):
		var x := (float(i) / segments) * strip_width
		var y := y_center + sin(x * frequency) * amplitude
		line.add_point(Vector2(x, y))
	guide_container.add_child(line)

	var segs := PackedVector2Array()
	for i in range(segments):
		var x1 := (float(i) / segments) * strip_width
		var x2 := (float(i + 1) / segments) * strip_width
		var y1 := y_center + sin(x1 * frequency) * amplitude
		var y2 := y_center + sin(x2 * frequency) * amplitude
		segs.append(Vector2(x1, y1))
		segs.append(Vector2(x2, y2))
	_baked_segments.append(segs)
	return line

func _create_saw_wave_guide(y_center: float = 150.0, amplitude: float = 30.0, frequency: float = 0.008, color: Color = Color(1, 0, 0, 0.5), width: float = 7.0, segments: int = 400) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.z_index = 2
	for i in range(segments + 1):
		var x := (float(i) / segments) * strip_width
		var t := fposmod(x * frequency, 1.0)
		var y := y_center + (t * 2.0 - 1.0) * amplitude
		line.add_point(Vector2(x, y))
	guide_container.add_child(line)

	var segs := PackedVector2Array()
	for i in range(segments):
		var x1 := (float(i) / segments) * strip_width
		var x2 := (float(i + 1) / segments) * strip_width
		var t1 := fposmod(x1 * frequency, 1.0)
		var t2 := fposmod(x2 * frequency, 1.0)
		var y1 := y_center + (t1 * 2.0 - 1.0) * amplitude
		var y2 := y_center + (t2 * 2.0 - 1.0) * amplitude
		segs.append(Vector2(x1, y1))
		segs.append(Vector2(x2, y2))
	_baked_segments.append(segs)
	return line

func _process(delta: float) -> void:
	if done:
		return

	scroll_offset += scroll_speed * delta
	parallax_bg.scroll_offset = Vector2(-scroll_offset, 0)

	decorate_timer -= delta
	decorate_timer = max(0.0, decorate_timer)
	timer_progress_bar.value = decorate_timer
	time_label.text = str(int(decorate_timer))
	_update_timer_color(decorate_timer / decorate_time)

	if decorate_timer <= 0.0:
		_finish()

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

func _start_frosting() -> void:
	is_drawing_frosting = true
	last_dollop_position = _mouse_to_strip_pos()
	_place_single_dollop(last_dollop_position)

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
			var pos := last_dollop_position + direction * dollop_spacing * i
			pos.x = fposmod(pos.x, strip_width)
			_place_single_dollop(pos)
		var last_pos := last_dollop_position + direction * dollop_spacing * steps
		last_pos.x = fposmod(last_pos.x, strip_width)
		last_dollop_position = last_pos

func _least_distance_between(a: Vector2, b: Vector2) -> Vector2:
	var dx := b.x - a.x
	if dx > strip_width * 0.5:
		dx -= strip_width
	elif dx < -strip_width * 0.5:
		dx += strip_width
	return Vector2(dx, b.y - a.y)

func _place_single_dollop(pos: Vector2) -> void:
	if dollop_count >= max_frosting_dollops:
		return
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
	Global.sound_manager.play("SwishSound")

func _mouse_to_strip_pos() -> Vector2:
	var local := cake_window.get_local_mouse_position()
	if cake_window.size.x <= 0 or cake_window.size.y <= 0:
		return Vector2.ZERO
	var scale_x := strip_width / cake_window.size.x
	var scale_y := strip_height / cake_window.size.y
	var viewport_pos := Vector2(local.x * scale_x, local.y * scale_y)
	var world_x := fmod(viewport_pos.x + scroll_offset, strip_width)
	if world_x < 0:
		world_x += strip_width
	return Vector2(world_x, viewport_pos.y)

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

func _finish() -> void:
	done = true
	is_drawing_frosting = false
	
	next_button.text = "Next!"

	_save_side_decorations_to_session()
	_calculate_side_decoration_accuracy()

	var frosting_accuracy := 0.0
	if _dollop_accuracy_count > 0:
		frosting_accuracy = _dollop_accuracy_sum / float(_dollop_accuracy_count)

	print("Side Frosting Accuracy: ", frosting_accuracy)
	print("Side Decoration Accuracy: ", decoration_accuracy)

	if GameSession.session_result:
		GameSession.session_result.side_frosting_accuracy = frosting_accuracy
		GameSession.session_result.side_decoration_accuracy = decoration_accuracy

	Global.sound_manager.stop("TickingSound")

	phase_label.text = "Done!"
	if next_button:
		next_button.show()

func _save_side_decorations_to_session() -> void:
	if GameSession.session_result == null:
		return

	GameSession.session_result.side_decorations_placed.clear()

	for child in decoration_container.get_children():
		if child.has_meta("is_target"):
			continue
		if not child.has_meta("decoration_id"):
			continue

		var placement := DecorationPlacement.new(
			child.get_meta("decoration_id"),
			child.position,
			child.rotation_degrees,
			child.scale
		)
		GameSession.session_result.side_decorations_placed.append(placement)

func _calculate_side_decoration_accuracy() -> void:
	_side_decoration_score_sum = 0.0
	_side_decoration_score_count = 0
	decoration_accuracy = 0.0

	if GameSession.session_result == null:
		return

	var targets := []
	for child in decoration_container.get_children():
		if child.has_meta("is_target"):
			targets.append(child)

	var placed := GameSession.session_result.side_decorations_placed

	for target in targets:
		if not is_instance_valid(target):
			continue
		var target_id: String = target.get_meta("decoration_id", "")
		if target_id == "":
			continue

		var best_distance := INF
		for p in placed:
			if p.id != target_id:
				continue
			var dist := p.position.distance_to(target.position)
			if dist < best_distance:
				best_distance = dist

		if best_distance == INF:
			continue

		var max_tolerance := 80.0
		var score: float = clamp(1.0 - best_distance / max_tolerance, 0.0, 1.0)
		_side_decoration_score_sum += score
		_side_decoration_score_count += 1

	if _side_decoration_score_count > 0:
		decoration_accuracy = _side_decoration_score_sum / float(_side_decoration_score_count)

func _on_next_pressed() -> void:
	if not done:
		_finish()

	# Recalculate final score using all accuracies
	if GameSession.session_result != null:
		var top: float = (GameSession.session_result.top_frosting_accuracy + GameSession.session_result.top_decoration_accuracy) / 2.0
		var side: float = (GameSession.session_result.side_frosting_accuracy + GameSession.session_result.side_decoration_accuracy) / 2.0
		GameSession.session_result.total_score = int(((top + side) / 2.0) * 100)

	var side_final_score := 0
	var order_id := ""

	if GameSession.session_result != null:
		# todo, remove this as it is overwriting current result
		side_final_score = GameSession.session_result.total_score
		if GameSession.session_result.order != null:
			order_id = GameSession.session_result.order.order_id

	GameSession.complete_order(order_id, side_final_score)

	# Go to hub
	Global.scene_manager.change_world_2d_scene("")
	Global.scene_manager.change_ui_scene(Constants.SCENE_PATHS.hub)

	# wait one frame 
	await get_tree().process_frame
	var hub = get_tree().current_scene
	if hub and hub.has_method("show_order_results"):
		hub.show_order_results()
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
