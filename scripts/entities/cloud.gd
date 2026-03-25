extends Node2D

## Nuvem decorativa que desloca lentamente da direita para a esquerda

var drift_speed: float = 0.0

func _ready() -> void:
	z_index = -2
	drift_speed = randf_range(18.0, 55.0)

	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/icons/icon.svg")  # placeholder - troque pelo sprite real
	var sc_x : float = randf_range(0.5, 1.2)
	var sc_y : float = randf_range(0.25, 0.55)
	sprite.scale = Vector2(sc_x, sc_y)
	sprite.modulate = Color(0.92, 0.95, 1.0, randf_range(0.35, 0.65))
	add_child(sprite)

func _process(delta: float) -> void:
	position.x -= drift_speed * delta
