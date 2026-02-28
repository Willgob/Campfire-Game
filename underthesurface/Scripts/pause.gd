extends CanvasLayer

@onready var blur = $TextureRect
@onready var menu = $Control   # or whatever your menu node is

var is_open := false

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


func _on_button_pressed() -> void:
	close_menu()

func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
