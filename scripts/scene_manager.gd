class_name SceneManager
extends Node

@export var world_2d : Node2D 
@export var ui : Control

var current_world_2d : Node
var current_ui : Control

func _ready() -> void:
	Global.scene_manager = self
	change_ui_scene("uid://b2vxniec67375") # main menu uid

# scene uid can also be path
func change_ui_scene(scene_uid : String, delete : bool = true, keep_running = false) -> void:
	if current_ui:
		if delete:
			current_ui.queue_free()
		elif keep_running:
			current_ui.visible = false
		else:
			ui.remove_child(current_ui)
	if not scene_uid:
		return
	var new_ui_scene = load(scene_uid).instantiate()
	ui.add_child(new_ui_scene)
	current_ui = new_ui_scene

func change_world_2d_scene(scene_uid : String, delete : bool = true, keep_running = false) -> void:
	if current_world_2d:
		if delete:
			current_world_2d.queue_free()
		elif keep_running:
			current_world_2d.visible = false
		else:
			world_2d.remove_child(current_world_2d)
	if not scene_uid:
		return
	var new_world_2d_scene = load(scene_uid).instantiate()
	world_2d.add_child(new_world_2d_scene)
	current_world_2d = new_world_2d_scene
