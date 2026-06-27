extends Control

@export var transition_time: float = 0.1

@onready var new_game_button: UIButton = $MainMenuUI/VBoxContainer/MarginContainer/MenuButtonsContainer/NewGame
@onready var continue_button: UIButton = $MainMenuUI/VBoxContainer/MarginContainer/MenuButtonsContainer/Continue
@onready var options_button: UIButton = $MainMenuUI/VBoxContainer/MarginContainer/MenuButtonsContainer/OptionsButton
@onready var quit_button: UIButton = $MainMenuUI/VBoxContainer/MarginContainer/MenuButtonsContainer/QuitButton
@onready var overwrite_save_modal: VBoxContainer = $MainMenuUI/VBoxContainer/MarginContainer/OverwriteSaveModal
@onready var yes_new_game_button: UIButton = $MainMenuUI/VBoxContainer/MarginContainer/OverwriteSaveModal/YesNewGameButton
@onready var no_new_game_button_2: UIButton = $MainMenuUI/VBoxContainer/MarginContainer/OverwriteSaveModal/NoNewGameButton2
@onready var menu_buttons_container: VBoxContainer = $MainMenuUI/VBoxContainer/MarginContainer/MenuButtonsContainer

@onready var main_menu_header: RichTextLabel = $MainMenuUI/VBoxContainer/Label
@onready var main_menu_header_background: UIStyleBox = $HeaderBackground

func _ready() -> void:
	overwrite_save_modal.hide()
	# Show Continue only if a save exists
	continue_button.visible = GameSession.has_save()

func _on_new_game_pressed() -> void:
	if GameSession.has_save():
		# Ask before overwriting
		overwrite_save_modal.show()
		main_menu_header.hide()
		menu_buttons_container.hide()
		main_menu_header_background.hide()
	else:
		_start_new_game()

func _on_yes_new_game_button_pressed() -> void:
	overwrite_save_modal.hide()
	_start_new_game()

func _on_no_new_game_button_2_pressed() -> void:
	main_menu_header.show()
	menu_buttons_container.show()
	main_menu_header_background.show()
	
	overwrite_save_modal.hide()

func _start_new_game() -> void:
	GameSession.new_game()
	Global.scene_manager.change_world_2d_scene(Constants.SCENE_PATHS.opening_scene)
	Global.scene_manager.change_ui_scene("")

func _on_continue_button_pressed() -> void:
	GameSession.load_save()
	if GameSession.has_flag("opening_scene_done"):
		Global.scene_manager.change_world_2d_scene("")
		Global.scene_manager.change_ui_scene(Constants.SCENE_PATHS.hub)
	else:
		Global.scene_manager.change_world_2d_scene(Constants.SCENE_PATHS.opening_scene)
		Global.scene_manager.change_ui_scene("")

func _on_options_button_pressed() -> void:
	await get_tree().create_timer(transition_time).timeout
	%MainMenuUI.hide()
	main_menu_header_background.hide()
	%OptionsUI.show()

func _on_quit_button_pressed() -> void:
	await get_tree().create_timer(transition_time).timeout
	get_tree().quit()

func _on_options_return_button_pressed() -> void:
	await get_tree().create_timer(transition_time).timeout
	%MainMenuUI.show()
	main_menu_header_background.show()
	%OptionsUI.hide()
