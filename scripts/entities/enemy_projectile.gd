extends Area2D

const SPEED: float = 340.0
const LIFETIME: float = 2.2

var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var _age: float = 0.0


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/icons/icon.svg")
	sprite.scale = Vector2(0.18, 0.18)
	sprite.modulate = Color(1.0, 0.45, 0.25)
	add_child(sprite)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_age += delta
	global_position += direction.normalized() * SPEED * delta
	if _age >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
