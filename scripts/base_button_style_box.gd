extends UIButton

func setup_polygon() -> void:
	await get_tree().create_timer(0.01).timeout
	var polygon : PackedVector2Array = []
	polygon.append(Vector2.ZERO)
	polygon.append(Vector2(0.0, size.y))
	polygon.append(size)
	polygon.append(Vector2(size.x, 0.0))
	$UIStyleBox.change_polygon($UIStyleBox/Polygon2D, polygon)
	
