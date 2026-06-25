extends Node2D

const DISK_RADIUS: float = 120.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, DISK_RADIUS, Color(0.85, 0.6, 0.2, 1))
	draw_circle(Vector2.ZERO, 12.0, Color(0.2, 0.1, 0.05, 1))
