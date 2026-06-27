class_name TopDecorationItem
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# todo, handle passing in the atlas some better way
const ATLAS: Texture2D = preload("uid://dpjckwm303qe2")
# this needs to change based on karrows real sprite size
# the project needs a set sprite size for all assets or else things might look very weird
const TILE_SIZE := 32


@export var fall_duration: float = 0.35
@export var start_scale: float = 2.5
@export var end_scale: float = 1.0
@export var cake_radius: float = 160.0

var _falling: bool = false
var _cake_ref: Node2D = null
var _fall_elapsed: float = 0.0
var _start_world_pos: Vector2 = Vector2.ZERO
var decoration_id: String = ""

func setup(decoration_data: Dictionary, cake_sprite: Node2D) -> void:
	_cake_ref = cake_sprite
	decoration_id = decoration_data.get("id", "")

	var atlas_pos: Vector2 = decoration_data.get("atlas_pos", Vector2.ZERO)
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = ATLAS
	atlas_tex.region = Rect2(atlas_pos.x * TILE_SIZE, atlas_pos.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	sprite.texture = atlas_tex

	var shape := CircleShape2D.new()
	shape.radius = decoration_data.get("collision_radius", TILE_SIZE * 0.5)
	collision.shape = shape

	end_scale = decoration_data.get("scale", Vector2.ONE).x
	set_meta("decoration_id", decoration_id)

func start_fall(world_pos: Vector2) -> void:
	_start_world_pos = world_pos
	global_position = world_pos
	self.scale = Vector2.ONE * start_scale
	_fall_elapsed = 0.0
	_falling = true

func _process(delta: float) -> void:
	if not _falling or _cake_ref == null:
		return

	_fall_elapsed += delta
	var t: float = clamp(_fall_elapsed / fall_duration, 0.0, 1.0)
	var t_ease := ease(t, -2.0)  # ease in

	# scale down from start_scale to end_scale
	self.scale = Vector2.ONE * lerp(start_scale, end_scale, t_ease)

	# stay at click position XY, visual shrink w/ Z movement
	global_position = _start_world_pos

	if t >= 1.0:
		var local_pos := _cake_ref.to_local(global_position)
		if local_pos.length() <= cake_radius:
			_land()
		else:
			# todo, change animation to keep shrinking? 
			# hit the floor and then dissapear? disable the collider?
			queue_free()  # missed the cake!

func _land() -> void:
	_falling = false
	var local_pos := _cake_ref.to_local(global_position)
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	_cake_ref.get_node("DecorationContainer").add_child(self)
	position = local_pos
	self.scale = Vector2.ONE * end_scale
	if anim_player.has_animation("land"):
		anim_player.play("land")
	elif anim_player.has_animation("idle"):
		anim_player.play("idle")
