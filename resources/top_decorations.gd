class_name TopDecorations
extends Resource

@export var frosting_type: String = "vanilla"
@export var frosting_color: Color = Color(1.0, 0.96, 0.88)
@export var frosting_style: String = "smooth"
@export var frosting_dots: Array[DotPlacement] = []
@export var frosting_paths: Array[PathPlacement] = []
@export var decorations: Array[OrderDecorationDef] = []
@export var preview_image: Texture2D = null

func _init():
	pass

func add_frosting_dot(pos: Vector2, col: Color = Color.RED, sz: float = 6.0, shp: String = "circle") -> DotPlacement:
	var d := DotPlacement.new(pos, col, sz, shp)
	frosting_dots.append(d)
	return d

func add_frosting_path(pts: PackedVector2Array, color_id: String = "red", w: float = 4.0, origin: Vector2 = Vector2.ZERO) -> PathPlacement:
	var p := PathPlacement.new(pts, color_id, w, origin)
	frosting_paths.append(p)
	return p

func add_decoration(item_id: String, pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> OrderDecorationDef:
	var d := OrderDecorationDef.new()
	d.id = item_id
	d.position = pos
	d.rotation_degrees = rot
	d.scale = scl
	decorations.append(d)
	return d
