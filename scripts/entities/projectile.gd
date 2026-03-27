extends Area2D

## Tiro básico – tecla R | CDR: 1.5s
const SPEED: float = 620.0
const LIFETIME: float = 2.0

var direction: float = 1.0
var damage: int = 2
var _age: float = 0.0

var _sprite: Sprite2D
var _rng := RandomNumberGenerator.new()
var _float_amp: float = 5.0
var _float_speed: float = 12.0
var _float_phase: float = 0.0
var _spin_speed: float = 0.0

func _ready() -> void:
	add_to_group("player_attack")
	_rng.randomize()
	_float_amp = _rng.randf_range(3.0, 7.0)
	_float_speed = _rng.randf_range(10.0, 16.0)
	_float_phase = _rng.randf_range(0.0, TAU)
	_spin_speed = _rng.randf_range(-6.0, 6.0)

	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/textures/effects/basic-attack.png")
	if not _sprite.texture:
		_sprite.texture = load("res://assets/icons/icon.svg")
	_sprite.scale = Vector2(0.25, 0.25)
	add_child(_sprite)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(max(damage, 1))
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	position.x += SPEED * direction * delta
	# “Saque flutuante”: visual flutua/rodopia, mas o hitbox segue reto
	if is_instance_valid(_sprite):
		_sprite.position.y = sin(_age * _float_speed + _float_phase) * _float_amp
		_sprite.rotation += _spin_speed * delta
	if _age >= LIFETIME:
		queue_free()
