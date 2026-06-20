extends Node2D

@export var dialogue_resource_uid : String
@export var reveal_timer : float = 0.02
@export var characters_revealed_per_timeout : int = 1
@export var characters_per_keystroke : int = 3

var dialogue_resource : DialogueResource = null
var dialogue_line : DialogueLine = null
var revealing : bool = false
var waiting_for_choice : bool = false
var reveal_wait_time : float = 0.0
var keystrokes : int = 0

func _ready() -> void:
	if not dialogue_resource_uid:
		return
	dialogue_resource = load(dialogue_resource_uid)
	
	Engine.get_singleton("DialogueManager").dialogue_ended.connect(end_scene)
	advance_dialogue("start")
	%RichTextLabel.text = dialogue_line.character + ": " + dialogue_line.text
	revealing = true

func _process(delta: float) -> void:
	if not dialogue_line:
		return
	
	if Input.is_action_just_pressed("lmb"):
		if not revealing and not waiting_for_choice:
			advance_dialogue(dialogue_line.next_id)
		else:
			%RichTextLabel.visible_ratio = 1.0
			revealing = false
	
	reveal_wait_time += delta
	if reveal_wait_time >= reveal_timer and revealing:
		reveal_wait_time = 0.0
		%RichTextLabel.visible_characters += characters_revealed_per_timeout
		if %RichTextLabel.visible_ratio >= 1.0:
			%RichTextLabel.visible_ratio = 1.0
			revealing = false
		keystrokes += 1
		if keystrokes >= characters_per_keystroke:
			Global.sound_manager.play("KeystrokeSound")
			keystrokes = 0

func advance_dialogue(next_id) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id)
	clear_choices()
	
	if dialogue_line:
		%RichTextLabel.text = dialogue_line.character + ": " + dialogue_line.text
		%RichTextLabel.visible_ratio = 0.0
		revealing = true
		if not dialogue_line.responses.is_empty():
			create_choices()
	else:
		%RichTextLabel.text = ""
		revealing = false

func create_choices() -> void:
	for response in dialogue_line.responses:
		var new_response = Button.new()
		%ResponseContainer.add_child(new_response)
		new_response.text = response.text
		new_response.pressed.connect(func(): advance_dialogue(response.next_id))
	waiting_for_choice = true

func clear_choices() -> void:
	waiting_for_choice = false
	for child in %ResponseContainer.get_children():
		child.queue_free()

func end_scene(_resource) -> void:
	Global.scene_manager.change_world_2d_scene("uid://cr6jrn8uade0l") # Game Controller scene
