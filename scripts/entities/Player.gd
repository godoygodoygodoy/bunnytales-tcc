extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _col_shape: CollisionShape2D = $CollisionShape2D
@onready var _camera: Camera2D = get_node_or_null("Camera2D")

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0
const DASH_SPEED: float = 600.0
const DASH_DURATION: float = 0.2
const DASH_COOLDOWN: float = 1.0
const BASE_MAX_JUMPS: int = 2

const ROLL_SPEED: float = 520.0
const ROLL_DURATION: float = 0.32
const ROLL_COOLDOWN: float = 0.55

const DASH_SHAKE_DURATION: float = 0.12
const DASH_SHAKE_INTENSITY: float = 4.0

const INV_DURATION: float = 1.0

const GALAXY_ATTACK_COOLDOWN: float = 20.0
const MELEE_COOLDOWN: float = 0.5
const SHOT_COOLDOWN: float = 1.5

var max_hp: int = 5
var hp: int = 5

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var jump_count: int = 0

var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_cooldown_timer: float = 0.0
var roll_direction: float = 1.0
var _roll_requested: bool = false

var _dash_shake_timer: float = 0.0
var _camera_base_pos: Vector2 = Vector2.ZERO

var inv_timer: float = 0.0
var galaxy_attack_cooldown_timer: float = 0.0
var melee_cooldown_timer: float = 0.0
var shot_cooldown_timer: float = 0.0

var _dash_upgrade_level: int = 0
var _extra_jump_unlocked: bool = false

var _is_dead: bool = false

var ability_system: Node = null
var xp_system: Node = null


func _ready() -> void:
	add_to_group("player")
	# Fallback visual: se não houver animações, usa o ícone padrão do Godot.
	if animated_sprite and (animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation("idle")):
		var icon_tex: Texture2D = load("res://assets/icons/icon.svg")
		var frames := SpriteFrames.new()
		for anim_name in ["idle", "run", "jump", "dash"]:
			frames.add_animation(anim_name)
			frames.add_frame(anim_name, icon_tex)
		animated_sprite.sprite_frames = frames
		animated_sprite.play("idle")
	if _camera:
		_camera_base_pos = _camera.position
	emit_signal("hp_changed", hp, max_hp)


func setup_systems(new_ability_system: Node, new_xp_system: Node) -> void:
	ability_system = new_ability_system
	xp_system = new_xp_system


func increase_max_hp(amount: int) -> void:
	if amount <= 0:
		return
	max_hp += amount
	hp = min(hp + amount, max_hp)
	emit_signal("hp_changed", hp, max_hp)


func improve_dash() -> bool:
	if _dash_upgrade_level >= 1:
		return false
	_dash_upgrade_level = 1
	return true


func unlock_extra_jump() -> bool:
	if _extra_jump_unlocked:
		return false
	_extra_jump_unlocked = true
	return true


func try_spend_hp_ratio(ratio: float) -> bool:
	if ratio <= 0.0:
		return false
	var loss: int = int(ceil(max_hp * ratio))
	if hp - loss < 1:
		return false
	hp -= loss
	emit_signal("hp_changed", hp, max_hp)
	return true


func take_damage(amount: int) -> void:
	if _is_dead or inv_timer > 0.0:
		return
	hp -= max(amount, 0)
	hp = max(hp, 0)
	inv_timer = INV_DURATION
	emit_signal("hp_changed", hp, max_hp)
	_blink()
	if hp <= 0:
		_die()


func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_Q:
			if galaxy_attack_cooldown_timer <= 0.0 and _can_use_attack("special"):
				if ability_system and ability_system.has_method("try_activate_sacrifice_buff"):
					ability_system.try_activate_sacrifice_buff(self)
				_launch_galaxy_attack()
				galaxy_attack_cooldown_timer = GALAXY_ATTACK_COOLDOWN
		KEY_E:
			if melee_cooldown_timer <= 0.0 and _can_use_attack("melee"):
				_launch_melee()
				melee_cooldown_timer = MELEE_COOLDOWN
		KEY_R:
			if shot_cooldown_timer <= 0.0 and _can_use_attack("projectile"):
				_launch_shot()
				shot_cooldown_timer = SHOT_COOLDOWN
		KEY_C:
			# Rolar no chão (esquiva). A execução real acontece no _physics_process.
			_roll_requested = true


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	galaxy_attack_cooldown_timer = max(galaxy_attack_cooldown_timer - delta, 0.0)
	melee_cooldown_timer = max(melee_cooldown_timer - delta, 0.0)
	shot_cooldown_timer = max(shot_cooldown_timer - delta, 0.0)
	if inv_timer > 0.0:
		inv_timer -= delta
	if roll_cooldown_timer > 0.0:
		roll_cooldown_timer = max(roll_cooldown_timer - delta, 0.0)
	if _dash_shake_timer > 0.0:
		_dash_shake_timer = max(_dash_shake_timer - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or jump_count < _get_max_jumps():
			velocity.y = JUMP_VELOCITY
			jump_count += 1

	var move_x := Input.get_axis("move_left", "move_right")
	var move_y := Input.get_axis("move_up", "move_down")
	var input_dir := Vector2(move_x, move_y)
	if input_dir.length() > 0.0:
		dash_direction = input_dir.normalized()

	# Inicia roll (somente no chão), independente do dash.
	if _roll_requested:
		_roll_requested = false
		if is_on_floor() and not is_dashing and not is_rolling and roll_cooldown_timer <= 0.0:
			is_rolling = true
			roll_timer = ROLL_DURATION
			roll_cooldown_timer = ROLL_COOLDOWN
			var hx := Input.get_axis("move_left", "move_right")
			if hx != 0.0:
				roll_direction = sign(hx)
			else:
				roll_direction = _facing()
			# I-frames durante o roll (esquiva).
			inv_timer = max(inv_timer, ROLL_DURATION)

	if Input.is_key_pressed(KEY_SHIFT) and not is_dashing and not is_rolling and dash_cooldown_timer <= 0.0 and _can_dash():
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN * (0.8 if _dash_upgrade_level > 0 else 1.0)
		# Tremida leve no início do dash
		_dash_shake_timer = DASH_SHAKE_DURATION

	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		if dash_timer <= 0.0:
			is_dashing = false
	elif is_rolling:
		roll_timer -= delta
		velocity.x = roll_direction * ROLL_SPEED
		# Mantém a gravidade padrão caso saia de uma quina.
		if not is_on_floor():
			velocity += get_gravity() * delta
		if roll_timer <= 0.0:
			is_rolling = false

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if not is_dashing and not is_rolling:
		var dir := Input.get_axis("move_left", "move_right")
		if dir:
			velocity.x = dir * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()
	_update_dash_shake()
	_update_animation()


func _update_dash_shake() -> void:
	if not _camera:
		return
	if _dash_shake_timer <= 0.0:
		_camera.position = _camera_base_pos
		return
	# Jitter pequeno horizontal (sensação de vento)
	var t: float = _dash_shake_timer / DASH_SHAKE_DURATION
	var amp: float = DASH_SHAKE_INTENSITY * clampf(t, 0.0, 1.0)
	_camera.position = _camera_base_pos + Vector2(randf_range(-amp, amp), randf_range(-amp * 0.35, amp * 0.35))


func _update_animation() -> void:
	var horizontal := Input.get_axis("move_left", "move_right")
	if horizontal != 0:
		animated_sprite.flip_h = horizontal < 0

	if is_dashing:
		if animated_sprite.animation != &"dash":
			animated_sprite.play("dash")
	elif is_rolling:
		# Sem animação própria por enquanto; reutiliza a do dash.
		if animated_sprite.animation != &"dash":
			animated_sprite.play("dash")
	elif not is_on_floor():
		if animated_sprite.animation != &"jump":
			animated_sprite.play("jump")
	elif horizontal != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")


func _die() -> void:
	_is_dead = true
	emit_signal("player_died")
	animated_sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self):
		return
	get_tree().reload_current_scene()


func _blink() -> void:
	for _i in range(4):
		animated_sprite.modulate.a = 0.25
		await get_tree().create_timer(0.09).timeout
		if not is_instance_valid(self) or _is_dead:
			return
		animated_sprite.modulate.a = 1.0
		await get_tree().create_timer(0.09).timeout
		if not is_instance_valid(self) or _is_dead:
			return


func _facing() -> float:
	return -1.0 if animated_sprite.flip_h else 1.0


func _body_center() -> Vector2:
	return _col_shape.global_position


func _damage_multiplier() -> float:
	if ability_system and ability_system.has_method("get_damage_multiplier"):
		return float(ability_system.get_damage_multiplier())
	return 1.0


func _get_attack_direction() -> Vector2:
	# Prioridade: se o player estiver apertando direção (WASD), usa ela.
	# Caso contrário, segue o ponteiro do mouse.
	var move_x := Input.get_axis("move_left", "move_right")
	var move_y := Input.get_axis("move_up", "move_down")
	var input_dir := Vector2(move_x, move_y)
	if input_dir.length() > 0.0:
		return input_dir.normalized()

	var mouse_dir := get_global_mouse_position() - _body_center()
	if mouse_dir.length() > 0.001:
		return mouse_dir.normalized()

	return Vector2(_facing(), 0.0)


func _launch_galaxy_attack() -> void:
	var attack = load("res://scripts/entities/galaxy_attack.gd").new()
	attack.direction = _get_attack_direction()
	attack.damage = int(round(3.0 * _damage_multiplier()))
	attack.global_position = _body_center()
	get_parent().add_child(attack)


func _launch_melee() -> void:
	var dir := _get_attack_direction()
	var attack = load("res://scripts/entities/melee_attack.gd").new()
	attack.damage = int(round(2.0 * _damage_multiplier()))
	attack.global_position = _body_center() + dir * 85.0
	attack.rotation = dir.angle()
	get_parent().add_child(attack)


func _launch_shot() -> void:
	var dir := _get_attack_direction()
	var proj = load("res://scripts/entities/projectile.gd").new()
	proj.damage = int(round(2.0 * _damage_multiplier()))
	proj.direction = dir
	proj.global_position = _body_center() + dir * 50.0
	get_parent().add_child(proj)


func _can_use_attack(attack_name: String) -> bool:
	if not ability_system:
		return true
	if ability_system.has_method("is_attack_unlocked"):
		return bool(ability_system.is_attack_unlocked(attack_name))
	return true


func _can_dash() -> bool:
	if not ability_system:
		return true
	if ability_system.has_method("is_movement_unlocked"):
		return bool(ability_system.is_movement_unlocked("dash"))
	return true


func _get_max_jumps() -> int:
	var jumps: int = BASE_MAX_JUMPS + (1 if _extra_jump_unlocked else 0)
	if not ability_system:
		return jumps
	if ability_system.has_method("is_movement_unlocked") and not ability_system.is_movement_unlocked("double_jump"):
		return 1
	return jumps


func export_progress_state() -> Dictionary:
	return {
		"max_hp": max_hp,
		"dash_upgrade_level": _dash_upgrade_level,
		"extra_jump_unlocked": _extra_jump_unlocked
	}


func import_progress_state(state: Dictionary) -> void:
	max_hp = int(state.get("max_hp", max_hp))
	_dash_upgrade_level = int(state.get("dash_upgrade_level", _dash_upgrade_level))
	_extra_jump_unlocked = bool(state.get("extra_jump_unlocked", _extra_jump_unlocked))
	hp = max_hp
	emit_signal("hp_changed", hp, max_hp)
