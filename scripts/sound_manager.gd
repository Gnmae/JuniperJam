class_name SoundManager
extends Node2D

var current_song : AudioStreamPlayer = null

var sounds : Dictionary

func _ready() -> void:
	Global.sound_manager = self
	for sound in get_children():
		if sound is AudioStreamPlayer or AudioStreamPlayer2D:
			sounds[sound.name] = sound
			if sound is AudioStreamPlayer2D:
				sound.finished.connect(_audio_2d_finished.bind(sound))

func play(sound_name : String) -> void:
	if not sounds.has(sound_name):
		return
	if sounds[sound_name].playing and sounds[sound_name].max_polyphony <= 1:
		return
	
	sounds[sound_name].play()

func play_song(song_name : String) -> void:
	if sounds.has(song_name):
		if current_song:
			current_song.stop()
		current_song = sounds[song_name]
		current_song.play()

func stop_song() -> void:
	if current_song:
		current_song.stop()

func stop(sound_name : String) -> void: 
	if sounds.has(sound_name):
		if sounds[sound_name] is AudioStreamPlayer2D:
			sounds[sound_name].finished.emit()
		else:
			sounds[sound_name].stop()

func play_audio_2d(sound_name : String, object : Node2D) -> void:
	if sounds.has(sound_name):
		if sounds[sound_name].is_playing() and sounds[sound_name].get("parameters/looping"):
			return
		sounds[sound_name].global_position = object.global_position
		sounds[sound_name].play()

func _audio_2d_finished(audio_2d : AudioStreamPlayer2D) -> void:
	audio_2d.global_position = global_position
	audio_2d.stop()
