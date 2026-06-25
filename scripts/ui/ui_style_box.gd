extends Control
class_name UIStyleBox

@export var polygon_wiggle_range : float = 10.0
@export var polygon_wiggle_speed : float = 0.5

@export var active : bool = true:
	set(value):
		active = value
		if active:
			start_animation()
		else:
			stop_animation()

var tweens : Array[Tween] = []

var original_polygons : Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is Polygon2D:
			original_polygons[child] = child.polygon
	if active:
		start_animation()

func start_animation() -> void:
	for child in get_children():
		if child is Polygon2D:
			animatePolygon(child, child.polygon)

func stop_animation() -> void:
	for tween in tweens:
		tween.kill()
	for child in get_children():
		if child is Polygon2D:
			child.polygon = original_polygons[child]

func animatePolygon(target: Polygon2D, polygon : PackedVector2Array) -> void:
	buildTween(target, polygon)

func buildTween(target : Polygon2D, polygon : PackedVector2Array) -> void:
	var tween := create_tween()
	tweens.append(tween)
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.finished.connect(_on_finished.bind(target, polygon))
	tween.finished.connect(func(): tweens.erase(tween))
	animateTween(tween, target, polygon)

func _on_finished(target : Polygon2D, polygon : PackedVector2Array) -> void:
	buildTween(target, polygon)

func animateTween(tween : Tween, target : Polygon2D, base_polygon : PackedVector2Array) -> void:
	for i in range(0,5):
		var new_polygon : PackedVector2Array = []
		for vector in base_polygon:
			new_polygon.append(vector + Vector2(randf_range(-polygon_wiggle_range,  polygon_wiggle_range), randf_range(-polygon_wiggle_range,  polygon_wiggle_range)))
		tween.tween_property(target, "polygon", new_polygon, 0.1/polygon_wiggle_speed)
	tween.tween_property(target, "polygon", base_polygon, 0.1/polygon_wiggle_speed)

func change_polygon(polygon_2d : Polygon2D, polygon : PackedVector2Array) -> void:
	if original_polygons.has(polygon_2d):
		original_polygons[polygon_2d] = polygon
		for child in get_children():
			if child == polygon_2d:
				child.polygon = polygon
