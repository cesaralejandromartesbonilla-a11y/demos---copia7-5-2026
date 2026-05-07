extends CanvasLayer

@onready var resume_button: Button = $ColorRect/CenterContainer/VBoxContainer/ResumeButton
@onready var menu_button: Button = $ColorRect/CenterContainer/VBoxContainer/MenuButton
@onready var exit_button: Button = $ColorRect/CenterContainer/VBoxContainer/ExitButton

func _ready() -> void:
	visible = false
	# Importante: el Process Mode de este nodo debe ser "Always" en el Inspector
	
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Por defecto es la tecla ESC
		toggle_pause()

func toggle_pause() -> void:
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ecenas/main_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
