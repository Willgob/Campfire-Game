extends CanvasLayer

@onready var blur = $TextureRect
@onready var menu = $Control

var is_open := false

func _ready():
	# REQUIRED → lets this CanvasLayer receive input while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if is_open:
		close_menu()
	else:
		open_menu()

func open_menu():
	is_open = true
	get_tree().paused = true

	visible = true
	blur.visible = true
	menu.visible = true

func close_menu():
	is_open = false
	get_tree().paused = false

	visible = false
	blur.visible = false
	menu.visible = false

func _on_button_pressed() -> void:
	close_menu()

func _on_button_3_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
