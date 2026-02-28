extends Camera2D

@export var strength: float = 40.0
@export var smooth_speed: float = 5.0

var target_position: Vector2

func _process(delta: float) -> void:
	var viewport_size: Vector2 = Vector2(get_viewport().size)
	var mouse_pos = get_viewport().get_mouse_position()

	var normalized = (mouse_pos / viewport_size - Vector2(0.5, 0.5)) * 2.0
	target_position = normalized * strength

	global_position = global_position.lerp(target_position, smooth_speed * delta)
