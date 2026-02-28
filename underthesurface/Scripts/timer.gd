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
