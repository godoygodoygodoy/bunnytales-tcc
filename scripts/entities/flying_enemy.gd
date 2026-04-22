extends CharacterBody2D

## Inimigo voador: segue o player no ar, mais lento.

signal died

const BASE_SPEED: float = 95.0
const BASE_HP_MAX: int = 2
const BASE_CONTACT_CD: float = 1.0
const BASE_XP_REWARD: int = 80
const TARGET_OFFSET_FAR: Vector2 = Vector2(0.0, -120.0) # paira acima quando está longe
const TARGET_OFFSET_NEAR: Vector2 = Vector2(0.0, 0.0)   # desce para encostar/atacar quando perto

var speed: float = BASE_SPEED
var hp_max: int = BASE_HP_MAX
var xp_reward: int = BASE_XP_REWARD
var contact_cd: float = BASE_CONTACT_CD

var hp: int = BASE_HP_MAX
var contact_timer: float = 0.0
var inv_timer: float = 0.0
var is_dead: bool = false

var _sprite: Sprite2D
var _hp_bar: ColorRect


func _ready() -> void:
	add_to_group("enemy")

	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/icons/icon.svg")
	_sprite.scale = Vector2(0.45, 0.45)
	_sprite.modulate = Color(0.45, 0.75, 1.0)
	add_child(_sprite)

	var hp_bg := ColorRect.new()
	hp_bg.size = Vector2(46.0, 6.0)
	hp_bg.position = Vector2(-23.0, -58.0)
	hp_bg.color = Color(0.08, 0.08, 0.12)
	hp_bg.z_index = 1
	add_child(hp_bg)

	_hp_bar = ColorRect.new()
	_hp_bar.size = Vector2(46.0, 6.0)
	_hp_bar.position = Vector2(-23.0, -58.0)
	_hp_bar.color = Color(0.35, 0.85, 1.0)
	_hp_bar.z_index = 2
	add_child(_hp_bar)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	col.shape = shape
	add_child(col)

	var dmg_area := Area2D.new()
	dmg_area.name = "DamageArea"
	var dcol := CollisionShape2D.new()
	var dshape := CircleShape2D.new()
	dshape.radius = 24.0
	dcol.shape = dshape
	dmg_area.add_child(dcol)
	dmg_area.body_entered.connect(_on_damage_body_entered)
	add_child(dmg_area)


func configure_for_phase(phase: int, _type: String = "flying") -> void:
	var p := maxi(1, phase)
	speed = BASE_SPEED + 6.0 * float(p - 1)
	hp_max = BASE_HP_MAX + int(floor(float(p - 1) / 2.0))
	xp_reward = BASE_XP_REWARD + (p - 1) * 25
	contact_cd = max(BASE_CONTACT_CD - 0.05 * float(p - 1), 0.6)
	hp = hp_max


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if contact_timer > 0.0:
		contact_timer -= delta
	if inv_timer > 0.0:
		inv_timer -= delta

	var player := get_tree().get_first_node_in_group("player")
	if player:
		var to_player: Vector2 = player.global_position - global_position
		var offset := TARGET_OFFSET_FAR
		if to_player.length() < 220.0 or abs(to_player.x) < 140.0:
			offset = TARGET_OFFSET_NEAR
		var target: Vector2 = player.global_position + offset
		var to_target: Vector2 = target - global_position
		if to_target.length() > 2.0:
			velocity = to_target.normalized() * speed
		else:
			velocity = Vector2.ZERO

		if _sprite:
			_sprite.flip_h = velocity.x < 0.0
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _on_damage_body_entered(body: Node) -> void:
	if is_dead:
		return
	if body.is_in_group("player") and contact_timer <= 0.0:
		if body.has_method("take_damage"):
			body.take_damage(1)
		contact_timer = contact_cd


func take_damage(amount: int) -> void:
	if is_dead or inv_timer > 0.0:
		return
	hp -= max(amount, 0)
	inv_timer = 0.18
	_update_hp_bar()
	_flash_white()
	if hp <= 0:
		_die()


func _update_hp_bar() -> void:
	if _hp_bar:
		_hp_bar.size.x = 46.0 * (float(max(hp, 0)) / float(hp_max))


func _flash_white() -> void:
	if not _sprite:
		return
	var original := _sprite.modulate
	_sprite.modulate = Color(1.0, 1.0, 1.0)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self) and not is_dead:
		_sprite.modulate = original


func _die() -> void:
	is_dead = true
	emit_signal("died", xp_reward)
	velocity = Vector2.ZERO
	if _sprite:
		_sprite.modulate = Color(0.35, 0.35, 0.45)
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(self):
		queue_free()
