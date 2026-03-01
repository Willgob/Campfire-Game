extends Control

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")


func _on_ready() -> void:
	$AnimationPlayer.play("fade_in") # Replace with function body.
