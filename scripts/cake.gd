extends Node2D

@export var spin_time: float = 5.0
@export var decorate_time: float = 20.0
@export var spin_speed_multiplier: float = 0.1
@export var min_speed: float = 50.0
@export var max_speed: float = 500.0

# Frosting Settings
@export var frosting_color: Color = Color(1.0, 0.85, 0.7, 1.0)
@export var max_frosting_dollops: int = 120
@export var dollop_interval: float = 0.05

# Frosting Path Accuracy
@export var frosting_tolerance: float = 15.0

# Order System
@export var current_order: Order
@export var target_color: Color = Color(1.0, 0.85, 0.3, 0.6)

# Node References
@onready var cake_top_sprite: Sprite2D = $CakeTop
@onready var plate: Sprite2D = $Plate
@onready var plate_area_2d: Area2D = $PlateArea2D
@onready var hand_sprite: Sprite2D = $PlateArea2D/HandSprite

@onready var spin_toggle_button: CheckButton = $SpinControls/VBoxContainer/SpinToggleButton
@onready var speed_v_slider: VSlider = $SpinControls/VBoxContainer/HBoxContainer/SpeedVSlider
@onready var speed_label: Label = $SpinControls/VBoxContainer/HBoxContainer/VBoxContainer/SpeedLabel
@onready var reverse_button: CheckButton = $SpinControls/VBoxContainer/ReverseButton

@onready var clock_sprite: Sprite2D = $TimerControls/HBoxContainer/ClockSprite
@onready var timer_progress_bar: ProgressBar = $TimerControls/HBoxContainer/TimerProgressBar
@onready var time_label: Label = $TimerControls/HBoxContainer/TimeLabel
@onready var phase_label: Label = $DebugControls/VBoxContainer/PhaseLabel

# Containers
@onready var frosting_container: Node2D = $CakeTop/FrostingContainer
@onready var decoration_container: Node2D = $CakeTop/DecorationContainer
@onready var next_button: Button = $DebugControls/VBoxContainer/NextButton

@onready var tool_button_container: HBoxContainer = $DecorationControls/HBoxContainer
@onready var decoration_pointer: Sprite2D = $DecorationPointer

@onready var order_ticket: Control = $OrderTicket

const POINTER_ATLAS_TILE_SIZE := 32
var _pointer_base_texture: Texture2D = null

# Game Variables
var decorate_timer: float = 0.0
var original_clock_position: Vector2 = Vector2.ZERO
var is_shaking_clock: bool = false

var last_mouse_pos: Vector2 = Vector2.ZERO
var last_active_speed: float = 10.0
var last_direction: int = 1
var is_dragging: bool = false
var mouse_click: bool = false
var drag_offset: float = 0.0

# State
var state: STATE = STATE.INITIAL
enum STATE {INITIAL, SPIN, DECORATE, DONE}

signal finished

# Decoration System
var decoration_targets: Array[Node] = []

# Frosting Dollop System
var dollop_count: int = 0
var is_drawing_frosting: bool = false
var _frosting_time_accum: float = 0.0

# Tool System
var active_tool: String = ""
var _tool_buttons: Dictionary = {}

# Frosting Path Guide
var _guide_lines: Array[Line2D] = []
var _baked_segments: Array = []
var _dollop_accuracy_sum: float = 0.0
var _dollop_accuracy_count: int = 0
var frosting_accuracy: float = 0.0

var decoration_accuracy: float = 0.0
var _decoration_score_sum: float = 0.0
var _decoration_score_count: int = 0

func _ready() -> void:
	if current_order == null:
		current_order = Order.get_order("order_02")
	apply_batter_color()
	setup_containers()
	setup_ui()
	setup_tools()
	if GameSession.session_result and speed_v_slider:
		var saved_speed := GameSession.session_result.spin_speed
		if saved_speed > 0.0:
			speed_v_slider.value = remap(saved_speed, 1.0, 10.0, min_speed, max_speed)
	if decoration_pointer:
		var tex := decoration_pointer.texture
		if tex is AtlasTexture:
			_pointer_base_texture = (tex as AtlasTexture).atlas
		else:
			_pointer_base_texture = tex
		decoration_pointer.hide()
	if plate_area_2d:
		plate_area_2d.input_event.connect(_on_plate_area_2d_input_event)
	next_button.text = "Finish Early"

	state = STATE.INITIAL
	update_phase_label()
	spin_enter()

# TOOL SYSTEM
func setup_tools() -> void:
	if not tool_button_container:
		return
	for tool_def in Constants.TOOLS:
		var btn := tool_button_container.get_node_or_null("ToolButton_" + tool_def.id)
		if btn == null:
			push_error("Missing tool button: ToolButton_" + tool_def.id)
			continue
		_tool_buttons[tool_def.id] = btn
		btn.toggle_mode = true
		btn.pressed.connect(_on_tool_button_pressed.bind(tool_def.id))

func _on_tool_button_pressed(tool_id: String) -> void:
	if active_tool == tool_id:
		set_active_tool("")
		return
	set_active_tool(tool_id)
	Global.sound_manager.play("MouseClickSound")

func set_active_tool(tool_id: String) -> void:
	if active_tool == "frosting":
		end_frosting()

	active_tool = tool_id

	for id in _tool_buttons:
		_tool_buttons[id].button_pressed = (id == tool_id)
	if tool_id == "":
		decoration_pointer.hide()
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return

	var tool_def := _get_tool_def(tool_id)
	if tool_def.is_empty():
		push_error("No tool def found for: " + tool_id)
		return

	print("Setting tool: ", tool_id, " atlas x: ", tool_def.pointer_atlas_pos.x * POINTER_ATLAS_TILE_SIZE)

	var atlas := AtlasTexture.new()
	atlas.atlas = _pointer_base_texture
	atlas.region = Rect2(
		tool_def.pointer_atlas_pos.x * POINTER_ATLAS_TILE_SIZE,
		tool_def.pointer_atlas_pos.y * POINTER_ATLAS_TILE_SIZE,
		POINTER_ATLAS_TILE_SIZE,
		POINTER_ATLAS_TILE_SIZE
	)
	decoration_pointer.texture = atlas
	decoration_pointer.show()

func _get_tool_def(tool_id: String) -> Dictionary:
	for tool_def in Constants.TOOLS:
		if tool_def.id == tool_id:
			return tool_def
	return {}

func _get_decoration_data(decoration_id: String) -> Dictionary:
	for d in Constants.TOP_DECORATIONS:
		if d.id == decoration_id:
			return d
	return {}

# INPUT & PROCESS
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.is_pressed():
			is_dragging = false
			mouse_click = false
			if hand_sprite:
				hand_sprite.visible = false
			if plate.get_parent() == plate_area_2d:
				plate.reparent($"..", true)

		if event.is_pressed() and state == STATE.DECORATE:
			var tool_def := _get_tool_def(active_tool)
			if tool_def.is_empty():
				pass
			elif tool_def.get("type") == "frosting":
				start_frosting()
			elif tool_def.get("type") == "decoration":
				_drop_decoration(tool_def)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		if active_tool != "" and _get_tool_def(active_tool).get("type") == "frosting":
			end_frosting()

	# Right click deselects tool
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		set_active_tool("")

func _is_mouse_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null

func _drop_decoration(tool_def: Dictionary) -> void:
	if _is_mouse_over_ui():
		return

	var dec_data := _get_decoration_data(tool_def.get("id", ""))
	if dec_data.is_empty():
		return

	var item: TopDecorationItem = load(Constants.DECORATION_SCENES.top_decoration).instantiate()
	get_parent().add_child(item)
	item.setup(dec_data, cake_top_sprite)
	item.start_fall(get_global_mouse_position())

func _on_plate_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if spin_toggle_button and spin_toggle_button.button_pressed:
			return
		if active_tool != "":
			return
		mouse_click = true
		is_dragging = true
		if hand_sprite:
			hand_sprite.visible = true
		var mouse_angle := (get_global_mouse_position() - plate_area_2d.global_position).angle()
		drag_offset = plate_area_2d.rotation - mouse_angle

func _process(delta: float) -> void:
	if spin_toggle_button and spin_toggle_button.button_pressed:
		plate.rotation += deg_to_rad(cake_top_sprite.rotation_speed * delta)
	elif is_dragging and mouse_click:
		var previous_rotation := plate_area_2d.rotation
		var mouse_angle := (get_global_mouse_position() - plate_area_2d.global_position).angle()
		plate_area_2d.rotation = mouse_angle + drag_offset
		if plate.get_parent() != plate_area_2d:
			plate.reparent(plate_area_2d, true)
		var delta_rotation := plate_area_2d.rotation - previous_rotation
		cake_top_sprite.rotation += delta_rotation

	if state == STATE.SPIN:
		spin_update(delta)
	elif state == STATE.DECORATE:
		decorate_update(delta)

	if is_shaking_clock and clock_sprite:
		var shake_amount = 3.0
		var shake_speed = 25.0
		clock_sprite.position = original_clock_position + Vector2(
			sin(Time.get_ticks_msec() / 1000.0 * shake_speed) * shake_amount,
			cos(Time.get_ticks_msec() / 1000.0 * shake_speed * 1.3) * shake_amount * 0.6
		)

	if active_tool != "" and decoration_pointer:
		decoration_pointer.global_position = get_global_mouse_position()

	if is_drawing_frosting:
		_frosting_time_accum += delta
		if _frosting_time_accum >= dollop_interval:
			_frosting_time_accum = 0.0
			var pos := cake_top_sprite.to_local(get_global_mouse_position())
			if dollop_count < max_frosting_dollops:
				place_single_dollop(pos)

func _calculate_decoration_accuracy() -> void:
	_decoration_score_sum = 0.0
	_decoration_score_count = 0

	if decoration_targets.is_empty() or GameSession.session_result == null:
		decoration_accuracy = 0.0
		return

	var placed := GameSession.session_result.top_decorations_placed

	for target in decoration_targets:
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

		var max_tolerance := 60.0
		var score : float = clamp(1.0 - best_distance / max_tolerance, 0.0, 1.0)

		_decoration_score_sum += score
		_decoration_score_count += 1

	if _decoration_score_count > 0:
		decoration_accuracy = _decoration_score_sum / float(_decoration_score_count)
	else:
		decoration_accuracy = 0.0

	print("Decoration accuracy: ", decoration_accuracy)

func spin_update(_delta: float) -> void:
	var current_mouse_pos = get_global_mouse_position()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_y_movement = (last_mouse_pos + current_mouse_pos).y
		if mouse_y_movement > 0.0:
			cake_top_sprite.rotation_speed += mouse_y_movement * 0.001
			cake_top_sprite.rotation_speed = clampf(cake_top_sprite.rotation_speed, min_speed, max_speed)
			hand_sprite.show()
		else:
			hand_sprite.hide()
		$SpinControls/VBoxContainer/SpeedLabel3.text = "Speed : " + str(floor(cake_top_sprite.current_rotation_speed))
	last_mouse_pos = current_mouse_pos
	if cake_top_sprite.current_rotation_speed > 5.0:
		Global.sound_manager.play("PlateSpinningSound")

func spin_enter() -> void:
	state = STATE.SPIN
	update_phase_label()
	
	spawn_decoration_targets()
	_setup_frosting_guide()
	
	if next_button:
		next_button.hide()

	var elapsed := 0.0
	#var ramp_duration := spin_time * 0.6
	#var target_speed := last_active_speed * last_direction

	while elapsed < spin_time:
		var delta := get_process_delta_time()
		elapsed += delta

		#if elapsed < ramp_duration:
			#var t := elapsed / ramp_duration
			#cake_top_sprite.rotation_speed = lerp(0.0, target_speed, t)
		#else:
			#cake_top_sprite.rotation_speed = target_speed

		var remaining := spin_time - elapsed
		if remaining <= 3.0 and phase_label:
			phase_label.text = "STARTING IN %d..." % int(ceil(remaining))
			phase_label.modulate = Color(1.0, 0.4, 0.2)

		await get_tree().process_frame

	#cake_top_sprite.rotation_speed = target_speed
	decorate_enter()


func setup_containers() -> void:
	if not frosting_container:
		frosting_container = Node2D.new()
		frosting_container.name = "FrostingContainer"
		cake_top_sprite.add_child(frosting_container)
	if not decoration_container:
		decoration_container = Node2D.new()
		decoration_container.name = "DecorationContainer"
		cake_top_sprite.add_child(decoration_container)

func setup_ui() -> void:
	if speed_v_slider:
		speed_v_slider.min_value = min_speed
		speed_v_slider.max_value = max_speed
		speed_v_slider.value = clamp(abs(cake_top_sprite.rotation_speed if cake_top_sprite else 0), min_speed, max_speed)
		speed_label.text = str(int(speed_v_slider.value))
	if speed_v_slider:
		speed_v_slider.value_changed.connect(_on_speed_slider_changed)
	if reverse_button:
		reverse_button.toggled.connect(_on_reverse_button_toggled)
	if spin_toggle_button:
		spin_toggle_button.toggled.connect(_on_spin_toggle_changed)
	decorate_timer = current_order.time_limit_seconds
	decorate_time = current_order.time_limit_seconds
	original_clock_position = clock_sprite.position
	is_shaking_clock = false
	#set_active_tool("")

	timer_progress_bar.max_value = current_order.time_limit_seconds
	timer_progress_bar.value = current_order.time_limit_seconds
	time_label.text = str(int(current_order.time_limit_seconds))
	update_timer_color(1.0)

func update_phase_label() -> void:
	if not phase_label:
		return
	match state:
		STATE.INITIAL:
			phase_label.text = "INITIALIZING..."
			phase_label.modulate = Color.WHITE
		STATE.SPIN:
			phase_label.text = "SPIN PHASE"
			phase_label.modulate = Color(0.4, 0.8, 1.0)
		STATE.DECORATE:
			phase_label.text = "DECORATE PHASE"
			phase_label.modulate = Color(1.0, 0.75, 0.2)
		STATE.DONE:
			phase_label.text = "Times Up!"
			phase_label.modulate = Color(0.3, 1.0, 0.4)
		_:
			phase_label.text = "UNKNOWN"

# FROSTING GUIDE LINES
func _setup_frosting_guide() -> void:
	for l in _guide_lines:
		if is_instance_valid(l):
			l.queue_free()
	_guide_lines.clear()
	_baked_segments.clear()
	_dollop_accuracy_sum = 0.0
	_dollop_accuracy_count = 0

	if current_order == null:
		return
	var top_decs = current_order.get_top_decorations()
	if top_decs == null:
		return

	for path in top_decs.frosting_paths:
		if path.points.size() < 2:
			continue
		var world_pts := PackedVector2Array()
		for p in path.points:
			world_pts.append(path.origin + p)
		var line := Line2D.new()
		line.name = "FrostingGuide"
		line.points = world_pts
		if path.closed and world_pts.size() > 0:
			line.add_point(world_pts[0])
		line.width = path.width
		line.default_color = Color(path.color.r, path.color.g, path.color.b, 0.4)
		line.z_index = 2
		cake_top_sprite.add_child(line)
		_guide_lines.append(line)
		var segs := PackedVector2Array()
		var count := world_pts.size()
		var limit := count - 1 if not path.closed else count
		for i in range(limit):
			segs.append(world_pts[i])
			segs.append(world_pts[(i + 1) % count])
		_baked_segments.append(segs)

# FROSTING ACCURACY
func _distance_to_all_guides(cake_local_pos: Vector2) -> float:
	var best := INF
	for segs: PackedVector2Array in _baked_segments:
		var i := 0
		while i + 1 < segs.size():
			best = min(best, _point_segment_distance(cake_local_pos, segs[i], segs[i + 1]))
			i += 2
	return best

func _point_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.dot(ab)
	if len_sq == 0.0:
		return p.distance_to(a)
	var t: float = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _record_dollop_accuracy(cake_local_pos: Vector2) -> void:
	if _baked_segments.is_empty():
		return
	var dist := _distance_to_all_guides(cake_local_pos)
	var score: float = clamp(1.0 - dist / frosting_tolerance, 0.0, 1.0)
	_dollop_accuracy_sum += score
	_dollop_accuracy_count += 1

# FROSTING DOLLOP SYSTEM
func start_frosting() -> void:
	is_drawing_frosting = true
	_frosting_time_accum = 0.0
	dollop_count = 0
	place_single_dollop(cake_top_sprite.to_local(get_global_mouse_position()))

func place_single_dollop(pos: Vector2) -> void:
	var scene_path = Constants.DECORATION_SCENES.frosting_dollop
	if scene_path == "":
		return
	var scene = load(scene_path)
	if not scene:
		return
	var dollop: Node = scene.instantiate()
	frosting_container.add_child(dollop)
	dollop.position = pos
	dollop.modulate = frosting_color
	dollop_count += 1
	_record_dollop_accuracy(pos)
	Global.sound_manager.play("SwishSound")

func end_frosting() -> void:
	is_drawing_frosting = false
	_frosting_time_accum = 0.0

# STATE MACHINE
func decorate_enter() -> void:
	update_phase_label()


	if next_button:
		next_button.text = "Finish Early"
		next_button.show()

	Global.sound_manager.play("TickingSound")

	state = STATE.DECORATE

func decorate_update(delta: float) -> void:
	if state != STATE.DECORATE:
		return
	decorate_timer -= delta
	timer_progress_bar.value = decorate_timer
	time_label.text = str(max(0, int(decorate_timer)))

	var progress: float = decorate_timer / decorate_time
	update_timer_color(progress)

	if progress < 0.25 and not is_shaking_clock:
		start_clock_shake()
	elif progress >= 0.25 and is_shaking_clock:
		stop_clock_shake()

	if decorate_timer <= 0:
		decorate_timer = 0
		state = STATE.DONE
		done_enter()
	if cake_top_sprite.current_rotation_speed > 5.0:
		Global.sound_manager.play("PlateSpinningSound")


func _on_next_button_pressed() -> void:
	if state == STATE.DECORATE:
		GameSession.current_order.time_left = decorate_timer
		decorate_timer = 0
		state = STATE.DONE
		done_enter()
	elif state == STATE.DONE:
		Global.scene_manager.change_world_2d_scene("")
		Global.scene_manager.change_ui_scene("res://scenes/side_decoration.tscn")

func _save_decorations_to_session() -> void:
	if GameSession.session_result == null:
		return
	GameSession.session_result.top_decorations_placed.clear()
	for child in decoration_container.get_children():
		if not child.has_meta("decoration_id"):
			continue
		var placement := DecorationPlacement.new(
			child.get_meta("decoration_id"),
			child.position,
			child.rotation_degrees,
			child.scale
		)
		GameSession.session_result.top_decorations_placed.append(placement)

func update_timer_color(progress: float) -> void:
	var color: Color
	if progress > 0.6:
		color = Color(0.2, 0.8, 0.3)
	elif progress > 0.3:
		color = Color(1.0, 0.85, 0.2)
	else:
		color = Color(0.9, 0.2, 0.2)
	timer_progress_bar.get("theme_override_styles/fill").bg_color = color

func start_clock_shake() -> void:
	is_shaking_clock = true

func stop_clock_shake() -> void:
	is_shaking_clock = false
	if clock_sprite:
		clock_sprite.position = original_clock_position
func done_enter() -> void:
	_save_decorations_to_session()

	_calculate_decoration_accuracy()

	if _dollop_accuracy_count > 0:
		frosting_accuracy = _dollop_accuracy_sum / float(_dollop_accuracy_count)
	else:
		frosting_accuracy = 0.0

	print("Frosting accuracy: ", frosting_accuracy)

	if GameSession.session_result != null:
		GameSession.session_result.top_frosting_accuracy = frosting_accuracy
		GameSession.session_result.top_decoration_accuracy = decoration_accuracy
		var combined := (frosting_accuracy + decoration_accuracy) / 2.0
		GameSession.session_result.top_final_score = int(combined * 100)

	set_active_tool("")
	decoration_pointer.hide()

	for btn in _tool_buttons.values():
		btn.disabled = true
	
	cake_top_sprite.rotation_speed = 0.0
	update_phase_label()
	finished.emit()
	Global.sound_manager.stop("TickingSound")
func _on_top_decoration_finished() -> void:
	if GameSession.session_result == null:
		return

	var final_score := GameSession.session_result.top_final_score
	var order_id := ""
	if GameSession.current_order != null:
		order_id = GameSession.current_order.id

	GameSession.complete_order(order_id, final_score)
func spawn_decoration_targets() -> void:
	for t in decoration_targets:
		if is_instance_valid(t):
			t.queue_free()
	decoration_targets.clear()

	if current_order == null:
		return

	var top_decs = current_order.get_top_decorations()
	if top_decs == null:
		return

	var placements: Array = []
	if "decorations" in top_decs:
		placements = top_decs.decorations
	elif top_decs.has_method("get_decorations"):
		placements = top_decs.get_decorations()

	if placements.is_empty():
		return

	var target_scene_path: String = Constants.SCENE_PATHS.get("decoration_target", "")
	if target_scene_path == "":
		push_error("Missing 'decoration_target' in Constants.SCENE_PATHS")
		return

	for placement in placements:
		if placement == null or placement.id == "":
			continue

		var target : DecorationTarget = load(target_scene_path).instantiate()
		cake_top_sprite.add_child(target)

		target.position = placement.position
		target.rotation_degrees = placement.rotation_degrees
		target.scale = placement.scale

		target.setup(placement)                    # Pass the DecorationPlacement directly

		target.set_meta("decoration_id", placement.id)
		target.set_meta("is_target", true)
		decoration_targets.append(target)

# UI CALLBACKS
func _on_speed_slider_changed(value: float) -> void:
	last_active_speed = value
	if speed_label:
		speed_label.text = str(int(value))
	if spin_toggle_button and spin_toggle_button.button_pressed:
		var dir: float = sign(cake_top_sprite.rotation_speed)
		if dir == 0:
			dir = float(last_direction)
		cake_top_sprite.rotation_speed = clamp(value * dir, -max_speed, max_speed)

func _on_reverse_button_toggled(_pressed: bool) -> void:
	if spin_toggle_button and spin_toggle_button.button_pressed:
		cake_top_sprite.rotation_speed = -cake_top_sprite.rotation_speed
	else:
		last_direction = -last_direction

func _on_spin_toggle_changed(pressed: bool) -> void:
	if pressed:
		cake_top_sprite.rotation_speed = last_active_speed * last_direction
		if speed_label:
			speed_label.text = str(int(last_active_speed))
	else:
		last_active_speed = abs(cake_top_sprite.rotation_speed)
		last_direction = sign(cake_top_sprite.rotation_speed)
		if last_direction == 0:
			last_direction = 1
		cake_top_sprite.rotation_speed = 0.0
		if speed_label:
			speed_label.text = "0"

# HELPERS
func apply_batter_color() -> void:
	if cake_top_sprite == null:
		return
	var mat := cake_top_sprite.material as ShaderMaterial
	if mat == null:
		return
	var color: Color = GameSession.cake_base_data.get("color", Color(1.0, 0.98, 0.9))
	mat.set_shader_parameter("base_color", color)

func clear_frosting() -> void:
	if frosting_container:
		for child in frosting_container.get_children():
			child.queue_free()
	dollop_count = 0


func _on_order_toggle_button_pressed() -> void:
	if order_ticket.visible:
		order_ticket.hide()
		return
	order_ticket.show()
