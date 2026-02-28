extends CharacterBody2D

const SPEED = 170
const GRAVITY = 30

const JUMP_FORCE = -230
const JUMP_HOLD_FORCE = -500
const DBL_JUMP_FORCE = -230
const DBL_JUMP_HOLD_FORCE = -500

const MAX_JUMP_HOLD_TIME = 0.12
const MAX_DBL_JUMP_HOLD_TIME = 0.08

const DASH_SPEED = 500
const DASH_TIME = 0.2
const DASH_COOLDOWN = 0.8

var jump_hold_timer = 0.0
var dbl_jump_hold_timer = 0.0

var is_jumping = false
var has_double_jumped = false

var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var is_dashing = false

func _physics_process(delta):
	# Dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Gravity (disabled during dash)
	if not is_dashing and not is_on_floor() and not is_jumping:
		velocity.y += GRAVITY

	# Horizontal movement
	var dir = 0
	if Input.is_action_pressed("move_right"):
		dir += 1
	if Input.is_action_pressed("move_left"):
		dir -= 1

	# --- NORMAL JUMP ---
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_FORCE
		is_jumping = true
		jump_hold_timer = MAX_JUMP_HOLD_TIME
		has_double_jumped = false

	# --- DOUBLE JUMP ---
	if Input.is_action_just_pressed("move_jump") and not is_on_floor() and not has_double_jumped:
		velocity.y = DBL_JUMP_FORCE
		is_jumping = true
		has_double_jumped = true
		dbl_jump_hold_timer = MAX_DBL_JUMP_HOLD_TIME

	# --- HOLD JUMP (normal or double) ---
	if is_jumping and Input.is_action_pressed("move_jump"):
		if jump_hold_timer > 0:
			velocity.y += JUMP_HOLD_FORCE * delta
			jump_hold_timer -= delta
		elif dbl_jump_hold_timer > 0:
			velocity.y += DBL_JUMP_HOLD_FORCE * delta
			dbl_jump_hold_timer -= delta
		else:
			is_jumping = false
	else:
		is_jumping = false

	# --- DASH START ---
	if Input.is_action_just_pressed("move_dash") and dash_cooldown_timer <= 0:
		is_dashing = true
		dash_timer = DASH_TIME
		dash_cooldown_timer = DASH_COOLDOWN

	# --- DASH LOGIC ---
	if is_dashing:
		velocity.x = dir * DASH_SPEED
		velocity.y = 0
		dash_timer -= delta

		if dash_timer <= 0:
			is_dashing = false
	else:
		velocity.x = dir * SPEED

	move_and_slide()

	# --- RESET ON GROUND ---
	if is_on_floor():
		is_dashing = false
		dash_cooldown_timer = 0
		has_double_jumped = false
