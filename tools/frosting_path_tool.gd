@tool
extends EditorScript

# Sprite size to fit within
# todo, grab this size from the sprite atlas cake.tscn uses
const SPRITE_SIZE := Vector2(392.0, 392.0)
const PADDING := 50.0  # inset from edge

const SAMPLE_COUNT := 128
const ORIGIN := Vector2.ZERO
const WIDTH := 4.0
const CLOSED := true

# Sine/saw bump settings per shape
const FREQUENCY := 6.0
const AMPLITUDE := 10.0

const OUTPUT_DIR := "res://resources/orders/frosting_paths/"

# shapes to generate
const SHAPES: Array = [
	{
		"shape": "circle",
		"color": Color(1.0, 1.0, 1.0),
		"filename": "circle_path.tres",
	},
	{
		"shape": "sine_circle",
		"color": Color(1.0, 0.8, 0.8),
		"filename": "sine_circle_path.tres",
		"frequency": 6.0,
		"amplitude": 10.0,
	},
	{
		"shape": "saw_circle",
		"color": Color(0.8, 1.0, 0.8),
		"filename": "saw_circle_path.tres",
		"frequency": 6.0,
		"amplitude": 10.0,
	},
	{
		"shape": "inner_circle",
		"color": Color(0.8, 0.8, 1.0),
		"filename": "inner_circle_path.tres",
		"radius_factor": 0.5,  # 50% of max radius = smaller ring
	},
]

func _run() -> void:
	var max_radius := (min(SPRITE_SIZE.x, SPRITE_SIZE.y) / 2.0) - PADDING

	var dir := DirAccess.open("res://")
	if not dir.dir_exists(OUTPUT_DIR):
		var err_dir := dir.make_dir_recursive(OUTPUT_DIR)
		if err_dir != OK:
			push_error("Failed to create directory: ", err_dir)
			return

	for shape_def in SHAPES:
		var shape: String = shape_def.get("shape", "circle")
		var color: Color = shape_def.get("color", Color.WHITE)
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
					pass  # just a plain circle at a smaller radius

			points.append(Vector2(cos(angle), sin(angle)) * r)

		var path := PathPlacement.new(points, color, WIDTH, ORIGIN)
		path.closed = CLOSED
		path.smooth = true
		path.style = shape

		var output_path := OUTPUT_DIR + filename
		var err := ResourceSaver.save(path, output_path)
		if err == OK:
			print("Saved: ", output_path, "  (radius: ", snappedf(radius, 0.1), ")")
		else:
			push_error("Failed to save ", filename, ": ", err)
