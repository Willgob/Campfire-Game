extends CharacterBody2D

# =========================
# CONSTANTS
# =========================
const SPEED = 170
const GRAVITY = 900

var debug_from = Vector2.ZERO
var debug_to = Vector2.ZERO

const JUMP_FORCE = -230
const JUMP_HOLD_FORCE = -500
const DBL_JUMP_FORCE = -230
const DBL_JUMP_HOLD_FORCE = -500

const MAX_JUMP_HOLD_TIME = 0.12
const MAX_DBL_JUMP_HOLD_TIME = 0.08

const DASH_SPEED = 500
const DASH_TIME = 0.2
const DASH_COOLDOWN = 0.8

# --- GRAPPLE ---
const GRAPPLE_LENGTH = 400
const AUTO_RELEASE_ANGLE = 135.0
const SWING_DAMPING = 0.995   # lower = loses energy faster

# =========================
# VARIABLES
# =========================
var facing_dir = 1

var is_jumping = false
var has_double_jumped = false
var jump_hold_timer = 0.0
var dbl_jump_hold_timer = 0.0

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0

# --- SWING ---
var is_swinging = false
var grapple_point = Vector2.ZERO
var swing_radius = 0.0
var swing_angle = 0.0
var angular_velocity = 0.0
var swing_start_angle = 0.0

func die():
	$AudioStreamPlayer2D.play()
	global_position = Vector2(330,200)

# =========================
func _physics_process(delta):

	# ---------------------------------
	# SWING MODE
	# ---------------------------------
	if is_swinging:
		_process_swing(delta)
		return

	# ---------------------------------
	# DASH COOLDOWN
	# ---------------------------------
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# ---------------------------------
	# GRAPPLE START (mouse aimed)
	# ---------------------------------
	if Input.is_action_just_pressed("move_grapple") \
	and not is_swinging:
		_start_grapple()

	# ---------------------------------
	# GRAVITY
	# ---------------------------------
	if not is_on_floor() and not is_dashing:
		velocity.y += GRAVITY * delta

	# ---------------------------------
	# HORIZONTAL MOVEMENT
	# ---------------------------------
	var dir = Input.get_axis("move_left", "move_right")

	if dir != 0:
		facing_dir = sign(dir)

	if not is_dashing:
		velocity.x = dir * SPEED
		if is_on_floor():
			$AnimatedSprite2D.play("run")
		if dir == -1:
			$AnimatedSprite2D.flip_h

	# ---------------------------------
	# JUMP
	# ---------------------------------
	if Input.is_action_just_pressed("move_jump"):
		if is_on_floor():
			_start_jump()
		elif not has_double_jumped:
			_start_double_jump()

	_handle_jump_hold(delta)

	# ---------------------------------
	# DASH
	# ---------------------------------
	if Input.is_action_just_pressed("move_dash") \
	and dash_cooldown_timer <= 0:
		_start_dash()

	if is_dashing:
		$Dash.play()
		velocity.x = facing_dir * DASH_SPEED
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	move_and_slide()

	# ---------------------------------
	# RESET ON GROUND
	# ---------------------------------
	if is_on_floor():
		has_double_jumped = false
		is_dashing = false


# =========================
# JUMP
# =========================
func _start_jump():
	velocity.y = JUMP_FORCE
	is_jumping = true
	jump_hold_timer = MAX_JUMP_HOLD_TIME
	dbl_jump_hold_timer = 0.0


func _start_double_jump():
	velocity.y = DBL_JUMP_FORCE
	is_jumping = true
	has_double_jumped = true
	dbl_jump_hold_timer = MAX_DBL_JUMP_HOLD_TIME
	jump_hold_timer = 0.0


func _handle_jump_hold(delta):

	if not Input.is_action_pressed("move_jump"):
		is_jumping = false
		return

	if jump_hold_timer > 0:
		$Jump.play()
		
		velocity.y += JUMP_HOLD_FORCE * delta
		jump_hold_timer -= delta

	elif dbl_jump_hold_timer > 0:
		velocity.y += DBL_JUMP_HOLD_FORCE * delta
		dbl_jump_hold_timer -= delta

	else:
		is_jumping = false


# =========================
# DASH
# =========================
func _start_dash():
	is_dashing = true
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN


# =========================
# GRAPPLE START
# =========================
func _start_grapple():

	print("Trying grapple")

	var space = get_world_2d().direct_space_state
	var from = global_position + Vector2(0, -4)

	var mouse_pos = get_global_mouse_position()
	var raw_dir = mouse_pos - from

	if raw_dir.length() < 5:
		print("Too close to player")
		return

	var direction = raw_dir.normalized()
	var to = from + direction * GRAPPLE_LENGTH

	# DEBUG ASSIGNMENTS
	debug_from = from
	debug_to = to
	queue_redraw()

	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 0xFFFFFFFF

	var result = space.intersect_ray(query)

	if result:
		print("HIT!")
		grapple_point = result.position
		swing_radius = (global_position - grapple_point).length()
		is_swinging = true
	else:
		print("No hit")


# =========================
# SWING PHYSICS
# =========================
func _process_swing(delta):

	# -------------------------
	# Get rope info
	# -------------------------
	var rope_vec = global_position - grapple_point
	var dist = rope_vec.length()

	if dist == 0:
		return

	var rope_dir = rope_vec / dist

	# -------------------------
	# Apply gravity
	# -------------------------
	velocity.y += GRAVITY * delta

	# -------------------------
	# Remove radial velocity
	# -------------------------
	var radial_velocity = velocity.dot(rope_dir)
	velocity -= rope_dir * radial_velocity

	# -------------------------
	# Move with collision FIRST
	# -------------------------
	move_and_slide()

	# -------------------------
	# Recalculate after move
	# -------------------------
	rope_vec = global_position - grapple_point
	dist = rope_vec.length()

	if dist == 0:
		return

	rope_dir = rope_vec / dist

	# -------------------------
	# Enforce rope length AFTER move
	# -------------------------
	if dist > swing_radius:
		global_position = grapple_point + rope_dir * swing_radius

		# Remove radial velocity AGAIN after snap
		radial_velocity = velocity.dot(rope_dir)
		velocity -= rope_dir * radial_velocity

	# -------------------------
	# Manual release
	# -------------------------
	if Input.is_action_just_pressed("move_jump"):
		_release_swing()

func _release_swing():
	is_swinging = false
	has_double_jumped = true
	# momentum already preserved in velocity
	
func _draw():
	draw_line(to_local(debug_from), to_local(debug_to), Color.YELLOW, 2)
	draw_circle(to_local(grapple_point), 4, Color.RED)
