@tool
extends EditorScript

const SPRITE_SIZE := Vector2(392.0, 392.0)
const PADDING := 50.0
const SAMPLE_COUNT := 128
const ORIGIN := Vector2.ZERO
const WIDTH := 4.0
const CLOSED := true
const FREQUENCY := 6.0
const AMPLITUDE := 10.0
const OUTPUT_DIR := "res://resources/orders/frosting_paths/"

const SHAPES: Array = [
	{
		"shape": "circle",
		"color_id": "yellow",
		"filename": "circle_path.tres",
	},
	{
		"shape": "sine_circle",
		"color_id": "red",
		"filename": "sine_circle_path.tres",
		"frequency": 6.0,
		"amplitude": 10.0,
	},
	{
		"shape": "saw_circle",
		"color_id": "green",
		"filename": "saw_circle_path.tres",
		"frequency": 6.0,
		"amplitude": 10.0,
	},
	{
		"shape": "inner_circle",
		"color_id": "blue",
		"filename": "inner_circle_path.tres",
		"radius_factor": 0.5,
	},
]

func _run() -> void:
	if not Constants:
		push_error("Constants autoload not found")
		return

	var frosting_colors: Array = Constants.FROSTING_COLORS
	if frosting_colors == null or frosting_colors.is_empty():
		push_error("FROSTING_COLORS is empty in Constants")
		return

	var color_lookup := {}
	for entry in frosting_colors:
		if entry is Dictionary and entry.has("id") and entry.has("color"):
			color_lookup[entry["id"]] = entry["color"]

	var max_radius := (min(SPRITE_SIZE.x, SPRITE_SIZE.y) / 2.0) - PADDING

	var dir := DirAccess.open("res://")
	if not dir.dir_exists(OUTPUT_DIR):
		var err_dir := dir.make_dir_recursive(OUTPUT_DIR)
		if err_dir != OK:
			push_error("Failed to create directory: ", err_dir)
			return

	for shape_def in SHAPES:
		var shape: String = shape_def.get("shape", "circle")
		var color_id: String = shape_def.get("color_id", "yellow")
		var filename: String = shape_def.get("filename", shape + "_path.tres")
		var radius_factor: float = shape_def.get("radius_factor", 1.0)
		var frequency: float = shape_def.get("frequency", FREQUENCY)
		var amplitude: float = shape_def.get("amplitude", AMPLITUDE)
		var radius := max_radius * radius_factor

		var points := PackedVector2Array()
		for i in range(SAMPLE_COUNT):
			var t := float(i) / float(SAMPLE_COUNT)
			var angle := t * TAU
			var r := radius
			match shape:
				"sine_circle":
					r += sin(angle * frequency) * amplitude
				"saw_circle":
					var saw := fmod(angle * frequency / TAU, 1.0)
					r += (saw - 0.5) * 2.0 * amplitude
				"inner_circle":
					pass
			points.append(Vector2(cos(angle), sin(angle)) * r)

		var output_path := OUTPUT_DIR + filename
		var path: PathPlacement

		if ResourceLoader.exists(output_path):
			path = ResourceLoader.load(output_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PathPlacement
			if path == null:
				push_error("Failed to load existing resource at: ", output_path)
				continue
			print("Updating existing: ", output_path)
		else:
			print("Creating new: ", output_path)
			path = PathPlacement.new()

		path.origin = ORIGIN
		path.color_id = color_id
		path.width = WIDTH
		path.closed = CLOSED
		path.smooth = true
		path.style = shape
		path.set_points(points)

		var err := ResourceSaver.save(path, output_path)
		if err == OK:
			print("Saved: ", output_path, " (radius: ", snappedf(radius, 0.1), ", points: ", points.size(), ")")
		else:
			push_error("Failed to save ", filename, ": ", err)
