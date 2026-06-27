class_name UIHSlider
extends HSlider

@export var bus_name : String

var bus_index : int

func _ready() -> void:
	if not bus_name:
		print("No bus name in export bus_name variable")
		return
	bus_index = AudioServer.get_bus_index(bus_name)
	
	value_changed.connect(_on_value_changed)

func _on_value_changed(_value : float) -> void:
	AudioServer.set_bus_volume_db(bus_index, -(20-_value/5))
