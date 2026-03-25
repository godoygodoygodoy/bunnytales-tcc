extends Area2D

## Tiro básico – tecla R | CDR: 1.5s
const SPEED: float = 620.0
const LIFETIME: float = 2.0

var direction: float = 1.0
var damage: int = 2
var _age: float = 0.0

func _ready() -> void:
	add_to_group("player_attack")

	var sprite := Sprite2D.new()
	sprite.texture = load("res://icon.svg")  # placeholder – troque pelo sprite real
	sprite.scale = Vector2(0.25, 0.25)
	sprite.modulate = Color(0.3, 0.85, 1.0)
	add_child(sprite)

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
	if _age >= LIFETIME:
		queue_free()
