extends CanvasLayer

@onready var label = $Label
var time_elapsed := 0.0

func _process(delta):
	time_elapsed += delta
	label.text = format_time(time_elapsed)

func format_time(t):
	var minutes = int(t) / 60
	var seconds = int(t) % 60
	var milliseconds = int((t - int(t)) * 100)

	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func _on_winzone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("gat gud")
		$AnimationPlayer.play("fade_out")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://Scenes/endscreen.tscn")


func _on_level_1_ready() -> void:
	$AnimationPlayer.play("fade_in")
