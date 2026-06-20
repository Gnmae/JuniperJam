class_name SoundManager
extends Node2D

var sounds : Dictionary

func _ready() -> void:
	Global.sound_manager = self
	for node in get_children():
		if node is AudioStreamPlayer:
			sounds[node.name] = node

func play(sound_name : String) -> void:
	if sounds.has(sound_name):
		sounds[sound_name].play()
