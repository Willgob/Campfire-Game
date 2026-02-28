extends Camera2D

@export var mouse_strength: float = 80.0
@export var smooth_speed: float = 6.0

var mouse_offset: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	var viewport_size: Vector2 = Vector2(get_viewport().size)
	var mouse_pos = get_viewport().get_mouse_position()

	var normalized = (mouse_pos / viewport_size - Vector2(0.5, 0.5)) * 2.0
	var target_offset = normalized * mouse_strength
	
	mouse_offset = mouse_offset.lerp(target_offset, smooth_speed * delta)
	offset = mouse_offset
