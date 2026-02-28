extends CharacterBody2D

const SPEED = 400
const JUMP_FORCE = -600
const GRAVITY = 2000

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0  # Reset vertical speed when grounded

	# Horizontal movement
	var dir = 0
	if Input.is_action_pressed("move_right"):
		dir += 1
	if Input.is_action_pressed("move_left"):
		dir -= 1

	velocity.x = dir * SPEED

	# Jumping
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	move_and_slide()
