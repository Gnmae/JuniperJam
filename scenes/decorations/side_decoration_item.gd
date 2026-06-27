class_name SideDecorationItem
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const ATLAS: Texture2D = preload("uid://b1ptbs1n4p5kx") 
const TILE_SIZE := 32

func setup(decoration_data: Dictionary) -> void:
	var atlas_pos: Vector2 = decoration_data.get("atlas_pos", Vector2.ZERO)
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = ATLAS
	atlas_tex.region = Rect2(atlas_pos.x * TILE_SIZE, atlas_pos.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	sprite.texture = atlas_tex

	var shape := CircleShape2D.new()
	shape.radius = decoration_data.get("collision_radius", TILE_SIZE * 0.5)
	collision.shape = shape

	self.scale = decoration_data.get("scale", Vector2.ONE)

func play_place_animation() -> void:
	if anim_player.has_animation("place"):
		anim_player.play("place")

func play_idle_animation() -> void:
	if anim_player.has_animation("idle"):
		anim_player.play("idle")
