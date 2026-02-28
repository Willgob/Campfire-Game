extends CharacterBody2D

# =========================
# CONSTANTS
# =========================
const SPEED = 170
const GRAVITY = 900

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

	var space = get_world_2d().direct_space_state
	var from = global_position
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - from).normalized()
	var to = from + direction * GRAPPLE_LENGTH

	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 1

	var result = space.intersect_ray(query)

	if result:
		grapple_point = result.position

		var rope_vec = global_position - grapple_point
		swing_radius = max(rope_vec.length(), 60.0)

		swing_angle = atan2(rope_vec.y, rope_vec.x)
		swing_start_angle = swing_angle

		var tangent = Vector2(-rope_vec.y, rope_vec.x).normalized()
		angular_velocity = velocity.dot(tangent) / swing_radius

		is_swinging = true


# =========================
# SWING PHYSICS
# =========================
func _process_swing(delta):

	# -----------------------------
	# Pendulum physics
	# -----------------------------
	var angular_acceleration = -(GRAVITY / swing_radius) * sin(swing_angle)

	angular_velocity += angular_acceleration * delta
	angular_velocity *= SWING_DAMPING
	swing_angle += angular_velocity * delta

	# Tangent direction
	var tangent = Vector2(
		-sin(swing_angle),
		cos(swing_angle)
	)

	# Convert angular motion to linear velocity
	velocity = tangent * (angular_velocity * swing_radius)

	# -----------------------------
	# MOVE WITH COLLISION
	# -----------------------------
	move_and_slide()

	# -----------------------------
	# Rope constraint (SAFE)
	# -----------------------------
	var rope_vec = global_position - grapple_point
	var dist = rope_vec.length()

	if dist > 0:
		var rope_dir = rope_vec / dist

		# Snap back to rope radius
		global_position = grapple_point + rope_dir * swing_radius

		# Remove radial velocity (prevents pushing through walls)
		var radial_velocity = velocity.dot(rope_dir)
		velocity -= rope_dir * radial_velocity

	# -----------------------------
	# Auto release
	# -----------------------------
	var angle_diff = wrapf(swing_angle - swing_start_angle, -PI, PI)
	if abs(rad_to_deg(angle_diff)) >= AUTO_RELEASE_ANGLE:
		_release_swing()
		return

	# Manual release
	if Input.is_action_just_pressed("move_jump"):
		_release_swing()


func _release_swing():
	is_swinging = false
	has_double_jumped = true
	# momentum already preserved in velocity
