extends Control

func _on_button_continue_pressed() -> void:
	#$AnimationPlayer.play("fade_out")
	#await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn") # Replace with function body.
	$Control.hide()
	$Control2.show()

func _on_button_pressed() -> void:
	$AnimationPlayer.play()
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func _on_button_2_pressed() -> void:
	$Control.hide()
	$Control2.show() # Replace with function body.

func _on_yes_pressed() -> void:
	$TextureRect.show()
	
func _on_no_pressed() -> void:
	$Control2.hide()
	$Control.show()


func _on_tree_entered() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	$ColorRect.hide()

func _on_finish_pressed() -> void:
	$Options2.hide()
	$Options.hide()
	$Control.show()

func _on_back_2_pressed() -> void:
	$Options2.hide()
	$Options.show()
	$Control.hide()

func _on_next_pressed() -> void:
	$Options.hide()
	$Options2.show()
	$Control.hide()

func _on_back_pressed() -> void:
	$Options.hide()
	$Options2.hide()
	$Control.show()


func _on_button_3_pressed() -> void:
	$Options.show()
	$Options2.hide()
	$Control.hide()
