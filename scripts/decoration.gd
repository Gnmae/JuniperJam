class_name Decoration
extends Node

static func instantiate_decoration_target() -> Node2D:
	var scene_path = Constants.SCENE_PATHS["decoration_target"]
	print("Loading scene from: ", scene_path)
	var packed = load(scene_path)
	print("Packed result: ", packed)
	return packed.instantiate()
