extends CharacterBody2D

@onready var animated_sprite : AnimatedSprite2D  = $AnimatedSprite2D
@onready var _col_shape       : CollisionShape2D = $CollisionShape2D

# ── Movimento ──────────────────────────────────────────────────────────────
const SPEED          : float = 300.0
const JUMP_VELOCITY  : float = -400.0
const DASH_SPEED     : float = 600.0
const DASH_DURATION  : float = 0.2
const DASH_COOLDOWN  : float = 1.0
const MAX_JUMPS      : int   = 2

# ── Vida ───────────────────────────────────────────────────────────────────
const HP_MAX        : int   = 5
const INV_DURATION  : float = 1.5   # invencibilidade após levar hit

# ── Ataques ────────────────────────────────────────────────────────────────
const GALAXY_ATTACK_COOLDOWN : float = 20.0
const MELEE_COOLDOWN         : float = 0.5
const SHOT_COOLDOWN          : float = 1.5

# ── Estado ─────────────────────────────────────────────────────────────────
var is_dashing   : bool  = false
var dash_timer   : float = 0.0
var dash_cooldown_timer : float = 0.0
var dash_direction      : Vector2 = Vector2.RIGHT
var jump_count          : int = 0

var hp                          : int   = HP_MAX
var inv_timer                   : float = 0.0
var galaxy_attack_cooldown_timer: float = 0.0
var melee_cooldown_timer        : float = 0.0
var shot_cooldown_timer         : float = 0.0
var _is_dead                    : bool  = false
var _spawn_position             : Vector2


func _ready() -> void:
	add_to_group("player")
	_spawn_position = global_position


# ── Input ──────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_Q:
			if galaxy_attack_cooldown_timer <= 0.0:
				_launch_galaxy_attack()
				galaxy_attack_cooldown_timer = GALAXY_ATTACK_COOLDOWN
		KEY_E:
			if melee_cooldown_timer <= 0.0:
				_launch_melee()
				melee_cooldown_timer = MELEE_COOLDOWN
		KEY_R:
			if shot_cooldown_timer <= 0.0:
				_launch_shot()
				shot_cooldown_timer = SHOT_COOLDOWN


# ── Ataques ────────────────────────────────────────────────────────────────
func _facing() -> float:
	return -1.0 if animated_sprite.flip_h else 1.0

func _body_center() -> Vector2:
	return _col_shape.global_position

func _launch_galaxy_attack() -> void:
	var attack = load("res://galaxy_attack.gd").new()
	attack.direction = _facing()
	attack.global_position = _body_center()
	get_parent().add_child(attack)

func _launch_melee() -> void:
	var attack = load("res://melee_attack.gd").new()
	attack.global_position = _body_center() + Vector2(85.0 * _facing(), 0.0)
	get_parent().add_child(attack)

func _launch_shot() -> void:
	var proj = load("res://projectile.gd").new()
	proj.direction = _facing()
	proj.global_position = _body_center() + Vector2(50.0 * _facing(), 0.0)
	get_parent().add_child(proj)


# ── Vida ───────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if _is_dead or inv_timer > 0.0:
		return
	hp -= amount
	inv_timer = INV_DURATION
	_blink()
	if hp <= 0:
		_die()

func _blink() -> void:
	for i in range(6):
		animated_sprite.modulate.a = 0.2
		await get_tree().create_timer(0.12).timeout
		if not is_instance_valid(self) or _is_dead:
			return
		animated_sprite.modulate.a = 1.0
		await get_tree().create_timer(0.12).timeout
		if not is_instance_valid(self) or _is_dead:
			return

func _die() -> void:
	_is_dead = true
	animated_sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
	set_physics_process(false)
	await get_tree().create_timer(1.8).timeout
	if not is_instance_valid(self):
		return
	# Ressurge
	hp = HP_MAX
	_is_dead = false
	velocity = Vector2.ZERO
	global_position = _spawn_position
	animated_sprite.modulate = Color.WHITE
	inv_timer = INV_DURATION
	set_physics_process(true)


# ── Loop principal ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Cooldowns
	galaxy_attack_cooldown_timer = max(galaxy_attack_cooldown_timer - delta, 0.0)
	melee_cooldown_timer         = max(melee_cooldown_timer - delta, 0.0)
	shot_cooldown_timer          = max(shot_cooldown_timer - delta, 0.0)
	if inv_timer > 0.0:
		inv_timer -= delta

	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	# Jump / Double Jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or jump_count < MAX_JUMPS:
			velocity.y = JUMP_VELOCITY
			jump_count += 1

	# Direção para dash
	var move_x := Input.get_axis("move_left", "move_right")
	var move_y := Input.get_axis("move_up", "move_down")
	var input_dir := Vector2(move_x, move_y)
	if input_dir.length() > 0:
		dash_direction = input_dir.normalized()

	# Dash (Shift)
	if Input.is_key_pressed(KEY_SHIFT) and not is_dashing and dash_cooldown_timer <= 0.0:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN

	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		if dash_timer <= 0.0:
			is_dashing = false

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# Movimento normal
	if not is_dashing:
		var dir := Input.get_axis("move_left", "move_right")
		if dir:
			velocity.x = dir * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	# Animação
	var dh := Input.get_axis("move_left", "move_right")
	if dh != 0:
		animated_sprite.flip_h = dh < 0

	if is_dashing:
		if animated_sprite.animation != &"dash":
			animated_sprite.play("dash")
	elif not is_on_floor():
		if animated_sprite.animation != &"jump":
			animated_sprite.play("jump")
	elif dh != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
