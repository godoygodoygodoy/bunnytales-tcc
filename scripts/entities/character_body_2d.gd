extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 1.0
const MAX_JUMPS = 2

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var jump_count: int = 0


func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	# Jump e Double Jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or jump_count < MAX_JUMPS:
			velocity.y = JUMP_VELOCITY
			jump_count += 1

	# Direção do dash (WASD)
	var move_x := Input.get_axis("move_left", "move_right")
	var move_y := Input.get_axis("move_up", "move_down")
	var input_dir := Vector2(move_x, move_y)

	if input_dir.length() > 0:
		dash_direction = input_dir.normalized()

	# Dash com Shift
	if Input.is_key_pressed(KEY_SHIFT) and not is_dashing and dash_cooldown_timer <= 0.0:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN

	# Atualiza dash
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		if dash_timer <= 0.0:
			is_dashing = false

	# Atualiza cooldown
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# Movimento normal
	if not is_dashing:
		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
