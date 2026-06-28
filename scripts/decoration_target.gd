class_name DecorationTarget
extends Node2D

var decoration_id: String = ""

func setup(placement: OrderDecorationDef) -> void:
	if placement == null:
		return
	decoration_id = placement.id
