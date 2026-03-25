extends CharacterBody2D

## Inimigo modular: melee e ranged com dificuldade por fase.

signal died

const BASE_PATROL_RANGE: float = 220.0
const BASE_CHASE_RANGE: float = 380.0
const BASE_SPEED_PATROL: float = 70.0
const BASE_SPEED_CHASE: float = 130.0
const BASE_GRAVITY: float = 900.0
const BASE_HP_MAX: int = 3
const BASE_CONTACT_CD: float = 1.0
const BASE_XP_REWARD: int = 100
const BASE_RANGED_DISTANCE: float = 220.0
const BASE_RANGED_CD: float = 1.4

var enemy_type: String = "melee"
var phase_difficulty: int = 1

var patrol_range: float = BASE_PATROL_RANGE
var chase_range: float = BASE_CHASE_RANGE
var speed_patrol: float = BASE_SPEED_PATROL
var speed_chase: float = BASE_SPEED_CHASE
var gravity_value: float = BASE_GRAVITY
var hp_max: int = BASE_HP_MAX
var contact_cd: float = BASE_CONTACT_CD
var xp_reward: int = BASE_XP_REWARD
var ranged_distance: float = BASE_RANGED_DISTANCE
var ranged_cooldown: float = BASE_RANGED_CD

var hp: int = BASE_HP_MAX
var patrol_origin: Vector2 = Vector2.ZERO
var facing: float = 1.0
var contact_timer: float = 0.0
var inv_timer: float = 0.0
var ranged_timer: float = 0.0
var is_dead: bool = false

var _sprite: Sprite2D
var _hp_bar: ColorRect

func _ready() -> void:
	add_to_group("enemy")
	patrol_origin = global_position

	# ---- Visual placeholder ----
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://icon.svg")
	_sprite.scale = Vector2(0.6, 0.6)
	_sprite.modulate = Color(1.0, 0.28, 0.28) if enemy_type == "melee" else Color(1.0, 0.55, 0.25)
	add_child(_sprite)

	# ---- Barra de HP ----
	var hp_bg := ColorRect.new()
	hp_bg.size = Vector2(54.0, 7.0)
	hp_bg.position = Vector2(-27.0, -68.0)
	hp_bg.color = Color(0.15, 0.0, 0.0)
	hp_bg.z_index = 1
	add_child(hp_bg)

	_hp_bar = ColorRect.new()
	_hp_bar.size = Vector2(54.0, 7.0)
	_hp_bar.position = Vector2(-27.0, -68.0)
	_hp_bar.color = Color(0.9, 0.1, 0.1)
	_hp_bar.z_index = 2
	add_child(_hp_bar)

	# ---- Colisão física ----
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 24.0
	shape.height = 58.0
	col.shape = shape
	add_child(col)

	# ---- Área de dano (machuca o player no contato) ----
	var dmg_area := Area2D.new()
	dmg_area.name = "DamageArea"
	var dcol := CollisionShape2D.new()
	var dshape := CapsuleShape2D.new()
	dshape.radius = 27.0
	dshape.height = 62.0
	dcol.shape = dshape
	dmg_area.add_child(dcol)
	dmg_area.body_entered.connect(_on_damage_body_entered)
	add_child(dmg_area)


func configure_for_phase(phase: int, type: String = "melee") -> void:
	phase_difficulty = max(1, phase)
	enemy_type = type

	patrol_range = BASE_PATROL_RANGE + 20.0 * float(phase_difficulty - 1)
	chase_range = BASE_CHASE_RANGE + 45.0 * float(phase_difficulty - 1)
	speed_patrol = BASE_SPEED_PATROL + 6.0 * float(phase_difficulty - 1)
	speed_chase = BASE_SPEED_CHASE + 14.0 * float(phase_difficulty - 1)
	gravity_value = BASE_GRAVITY
	hp_max = BASE_HP_MAX + phase_difficulty - 1
	xp_reward = BASE_XP_REWARD + (phase_difficulty - 1) * 40
	contact_cd = max(BASE_CONTACT_CD - 0.1 * float(phase_difficulty - 1), 0.5)
	ranged_distance = BASE_RANGED_DISTANCE + 25.0 * float(phase_difficulty - 1)
	ranged_cooldown = max(BASE_RANGED_CD - 0.1 * float(phase_difficulty - 1), 0.8)
	hp = hp_max


func _spawn_ranged_projectile(player: Node2D) -> void:
	var projectile := load("res://enemy_projectile.gd").new()
	projectile.global_position = global_position + Vector2(0.0, -16.0)
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.damage = 1 + max(phase_difficulty - 1, 0)
	get_parent().add_child(projectile)


func _on_damage_body_entered(body: Node) -> void:
	if is_dead:
		return
	if enemy_type != "melee":
		return
	if body.is_in_group("player") and contact_timer <= 0.0:
		body.take_damage(1)
		contact_timer = contact_cd


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity_value * delta

	if contact_timer > 0.0:
		contact_timer -= delta
	if inv_timer > 0.0:
		inv_timer -= delta
	if ranged_timer > 0.0:
		ranged_timer -= delta

	var player := get_tree().get_first_node_in_group("player")

	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist < chase_range:
			if enemy_type == "melee":
				facing = sign(player.global_position.x - global_position.x)
				velocity.x = facing * speed_chase
			else:
				facing = sign(global_position.x - player.global_position.x)
				if dist < ranged_distance * 0.75:
					velocity.x = facing * speed_patrol
				elif dist > ranged_distance:
					velocity.x = -facing * speed_patrol
				else:
					velocity.x = move_toward(velocity.x, 0.0, speed_patrol)

				if ranged_timer <= 0.0:
					ranged_timer = ranged_cooldown
					_spawn_ranged_projectile(player)
		else:
			if global_position.x > patrol_origin.x + patrol_range:
				facing = -1.0
			elif global_position.x < patrol_origin.x - patrol_range:
				facing = 1.0
			velocity.x = facing * speed_patrol
	else:
		if global_position.x > patrol_origin.x + patrol_range:
			facing = -1.0
		elif global_position.x < patrol_origin.x - patrol_range:
			facing = 1.0
		velocity.x = facing * speed_patrol

	if _sprite:
		_sprite.flip_h = facing < 0

	move_and_slide()
func take_damage(amount: int) -> void:
	if is_dead or inv_timer > 0.0:
		return
	hp -= amount
	inv_timer = 0.25
	_update_hp_bar()
	_flash_white()
	if hp <= 0:
		_die()

func _update_hp_bar() -> void:
	if _hp_bar:
		_hp_bar.size.x = 54.0 * (float(max(hp, 0)) / float(hp_max))

func _flash_white() -> void:
	if not _sprite:
		return
	_sprite.modulate = Color(1.0, 1.0, 1.0)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and not is_dead:
		_sprite.modulate = Color(1.0, 0.28, 0.28) if enemy_type == "melee" else Color(1.0, 0.55, 0.25)

func _die() -> void:
	is_dead = true
	emit_signal("died", xp_reward)
	velocity = Vector2.ZERO
	if _sprite:
		_sprite.modulate = Color(0.4, 0.4, 0.4)
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(self):
		queue_free()
