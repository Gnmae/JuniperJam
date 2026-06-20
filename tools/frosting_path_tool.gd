@tool
extends EditorScript

const OUTPUT_PATH := "res://resources/orders/frosting_paths/circle_path.tres"

const SHAPE := "sine_circle"   # "circle", "sine_circle", "saw_circle"
const RADIUS := 50.0
const FREQUENCY := 6.0         # bumps around the ring (sine/saw only)
const AMPLITUDE := 10.0        # height of bumps (sine/saw only)
const SAMPLE_COUNT := 128      # how many points to generate
const ORIGIN := Vector2.ZERO
const COLOR := Color(1.0, 1.0, 1.0)
const WIDTH := 4.0
const CLOSED := true

func _run() -> void:
	var points := PackedVector2Array()

	for i in range(SAMPLE_COUNT):
		var t := float(i) / float(SAMPLE_COUNT)
		var angle := t * TAU
		var r := RADIUS

		match SHAPE:
			"sine_circle":
				r += sin(angle * FREQUENCY) * AMPLITUDE
			"saw_circle":
				var saw := fmod(angle * FREQUENCY / TAU, 1.0)
				r += (saw - 0.5) * 2.0 * AMPLITUDE

		points.append(Vector2(cos(angle), sin(angle)) * r)

	# Ensure directory exists
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("res://resources/orders/frosting_paths"):
		var err_dir := dir.make_dir_recursive("res://resources/orders/frosting_paths")
		if err_dir != OK:
			push_error("Failed to create directory: ", err_dir)
			return

	var path := PathPlacement.new(points, COLOR, WIDTH, ORIGIN)
	path.closed = CLOSED
	path.smooth = true
	path.style = SHAPE

	var err := ResourceSaver.save(path, OUTPUT_PATH)
	if err == OK:
		print("Saved frosting path to: ", OUTPUT_PATH)
	else:
		push_error("Failed to save: ", err)
