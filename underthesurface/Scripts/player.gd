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

var is_swinging = false
var grapple_point = Vector2.ZERO
var swing_radius = 0.0
var swing_start_angle = 0.0

# Debug
var debug_grapple_from = Vector2.ZERO
var debug_grapple_to = Vector2.ZERO
var show_debug_grapple = false

# =========================
func _ready():
	pass


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
	# GRAPPLE START
	# ---------------------------------
	if Input.is_action_just_pressed("move_grapple") \
	and not is_on_floor() \
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

	queue_redraw()


# =========================
# JUMP HELPERS
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
# GRAPPLE
# =========================
func _start_grapple():

	debug_grapple_from = global_position
	debug_grapple_to = global_position + Vector2(facing_dir * GRAPPLE_LENGTH, -120)
	show_debug_grapple = true

	var space = get_world_2d().direct_space_state
	var from = global_position
	var to = debug_grapple_to

	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 1

	var result = space.intersect_ray(query)

	if result:

		grapple_point = result.position
		var rope_vec = global_position - grapple_point

		swing_radius = max(rope_vec.length(), 60.0)
		swing_start_angle = atan2(rope_vec.y, rope_vec.x)

		is_swinging = true
		# IMPORTANT: keep current velocity so swing has momentum
		# (removed: velocity = Vector2.ZERO)

	show_debug_grapple = false


# =========================
# SWING PROCESS
# =========================
func _process_swing(delta):
	# Vector from grapple point to player
	var rope_vec = global_position - grapple_point
	var rope_dir = rope_vec.normalized()

	# Tangent vector for swinging (90° rotated)
	var tangent = Vector2(-rope_dir.y, rope_dir.x)

	# Proper gravity projection along tangent
	var gravity_vec = Vector2(0, GRAVITY)
	var gravity_tangent = gravity_vec.dot(tangent)
	velocity += gravity_tangent * tangent * delta

	# If we're completely still, give a tiny nudge so it doesn't "stick"
	if velocity.length() < 5.0:
		velocity += tangent * 20.0 * delta

	# Update position along tangent
	global_position += velocity * delta

	# Constrain to rope radius
	rope_vec = global_position - grapple_point
	global_position = grapple_point + rope_vec.normalized() * swing_radius

	# Remove radial velocity (toward/away from grapple)
	var radial_velocity = velocity.dot(rope_vec.normalized())
	velocity -= rope_vec.normalized() * radial_velocity

	# Track swing angle for auto-release
	var current_angle = atan2(rope_vec.y, rope_vec.x)
	var angle_diff = wrapf(current_angle - swing_start_angle, -PI, PI)

	if abs(rad_to_deg(angle_diff)) >= AUTO_RELEASE_ANGLE:
		is_swinging = false
		return

	# Jump release
	if Input.is_action_just_pressed("move_jump"):
		is_swinging = false
		velocity = tangent * velocity.length() + Vector2(0, JUMP_FORCE)
		has_double_jumped = true


# =========================
# DEBUG DRAW
# =========================
func _draw():
	if show_debug_grapple:
		draw_line(
			to_local(debug_grapple_from),
			to_local(debug_grapple_to),
			Color.RED,
			2.0
		)
