extends Area2D

## Ataque corpo-a-corpo – tecla E | CDR: 0.5s
const LIFETIME: float = 0.22

var _age: float = 0.0
var _hit_bodies: Array = []
var damage: int = 2

func _ready() -> void:
	add_to_group("player_attack")

	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/icons/icon.svg")  # placeholder - troque pelo sprite real
	sprite.scale = Vector2(0.55, 0.55)
	sprite.modulate = Color(1.0, 0.85, 0.2)
	add_child(sprite)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(90.0, 70.0)
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and not body in _hit_bodies:
		_hit_bodies.append(body)
		if body.has_method("take_damage"):
			body.take_damage(max(damage, 1))

func _process(delta: float) -> void:
	_age += delta
	# Fade out ao desaparecer
	modulate.a = clamp(1.0 - _age / LIFETIME, 0.0, 1.0)
	if _age >= LIFETIME:
		queue_free()
