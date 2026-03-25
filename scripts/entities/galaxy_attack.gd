extends Area2D

## Galaxy Attack – projétil especial do Q (CDR: 20s)
const SPEED: float = 350.0
const LIFETIME: float = 3.5

var direction: float = 1.0
var damage: int = 3
var _age: float = 0.0

func _ready() -> void:
	add_to_group("player_attack")

	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/textures/effects/galaxy_attack.png")
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	var tex_size := sprite.texture.get_size() * 1.5
	shape.size = tex_size
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(max(damage, 1))
		# Galaxy atinge todos por um instante, não some logo
	elif body.is_in_group("player"):
		pass  # não acerta o próprio player

func _process(delta: float) -> void:
	_age += delta
	position.x += SPEED * direction * delta
	# Efeito pulsante
	scale = Vector2.ONE * (1.0 + 0.1 * sin(_age * 8.0))
	if _age >= LIFETIME:
		queue_free()
