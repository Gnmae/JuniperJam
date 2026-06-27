class_name TopDecorations
extends Resource

# Container for everything that goes on top of the cake base.
@export var frosting_type: String = "vanilla"           # "vanilla", "chocolate", "strawberry", "matcha", "blueberry"...
@export var frosting_color: Color = Color(1.0, 0.96, 0.88)  # Creamy off-white
@export var frosting_style: String = "smooth"           # "smooth", "swirled", "textured", "ombre"

@export var frosting_dots: Array[DotPlacement] = []
@export var frosting_paths: Array[PathPlacement] = []
@export var decorations: Array[DecorationPlacement] = []

# preview image like karrow/kart mentioned. will have to come up with a way to generate these based on player actions
@export var preview_image: Texture2D = null

func _init():
	pass

## Helper methods (very useful when generating orders in code)
func add_frosting_dot(pos: Vector2, col: Color = Color.RED, sz: float = 6.0, shp: String = "circle") -> DotPlacement:
	var d := DotPlacement.new(pos, col, sz, shp)
	frosting_dots.append(d)
	return d

func add_frosting_path(pts: PackedVector2Array, color_id: String = "red", w: float = 4.0, origin: Vector2 = Vector2.ZERO) -> PathPlacement:
	var p := PathPlacement.new(pts, color_id, w, origin)
	frosting_paths.append(p)
	return p

func add_decoration(item_id: String, pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> DecorationPlacement:
	var d := DecorationPlacement.new(item_id, pos, rot, scl)
	decorations.append(d)
	return d
