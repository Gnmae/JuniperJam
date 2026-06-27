@tool
extends EditorScript

const OUTPUT_DIR := "res://resources/orders/frosting_paths/side/"
const STRIP_WIDTH := 1200.0
const SAMPLE_COUNT := 300

const SHAPES: Array = [
	{
		"name": "side_sine",
		"filename": "side_sine_wave.tres",
		"color": Color(0.4, 0.9, 0.5),
		"width": 7.0,
		"y_center": 160.0,
		"amplitude": 28.0,
		"frequency": 4.0,
		"closed": false
	},
	{
		"name": "side_saw",
		"filename": "side_saw_wave.tres",
		"color": Color(1.0, 0.75, 0.3),
		"width": 7.0,
		"y_center": 210.0,
		"amplitude": 25.0,
		"frequency": 5.0,
		"closed": false
	},
	{
		"name": "side_straight",
		"filename": "side_horizontal_line.tres",
		"color": Color(0.9, 0.4, 0.4),
		"width": 10.0,
		"y_center": 140.0,
		"closed": false
	}
]

func _run() -> void:
	var dir := DirAccess.open("res://")
	if not dir.dir_exists(OUTPUT_DIR):
		dir.make_dir_recursive(OUTPUT_DIR)

	for shape in SHAPES:
		var points := PackedVector2Array()
		var shape_name: String = shape.get("name", "")
		var y_center: float = shape.get("y_center", 150.0)
		var amplitude: float = shape.get("amplitude", 0.0)
		var frequency: float = shape.get("frequency", 1.0)
		var closed: bool = shape.get("closed", false)
		var color: Color = shape.get("color", Color.WHITE)
		var width: float = shape.get("width", 6.0)

		for i in range(SAMPLE_COUNT):
			var t := float(i) / float(SAMPLE_COUNT - 1)
			var x := t * STRIP_WIDTH
			var y := y_center

			if shape_name == "side_sine":
				y += sin(t * frequency * TAU) * amplitude
			elif shape_name == "side_saw":
				var saw := fmod(t * frequency, 1.0)
				y += (saw - 0.5) * 2.0 * amplitude
			# straight line falls through and keeps y_center

			points.append(Vector2(x, y))

		print("Generated ", shape_name, " with ", points.size(), " points")

		var path := PathPlacement.new(points, color, width, Vector2.ZERO)
		path.closed = closed
		path.smooth = true
		path.style = shape_name

		var output_path: String = OUTPUT_DIR + shape.get("filename", "unknown.tres")
		var err := ResourceSaver.save(path, output_path)

		if err == OK:
			print("Saved: ", output_path)
		else:
			push_error("Failed to save: ", output_path)
