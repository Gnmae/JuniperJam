class_name DecorationTarget
extends Node2D

var decoration_id: String = ""

func setup(dec: DecorationPlacement) -> void:
	decoration_id = dec.id
