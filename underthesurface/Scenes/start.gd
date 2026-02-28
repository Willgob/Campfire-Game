extends Control


func _on_button_continue_pressed() -> void:
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn") # Replace with function body.
	$Control.hide()
	$Control2.show()

func _on_button_pressed() -> void:
	$AnimationPlayer.play()
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func _on_button_2_pressed() -> void:
	get_tree().quitdw() # Replace with function body.
