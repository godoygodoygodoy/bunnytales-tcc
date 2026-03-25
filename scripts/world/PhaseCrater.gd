extends Area2D

signal player_entered_crater


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	_build_visual()


func _build_visual() -> void:
	# Placeholder visual sem textura para a cratera (desenhada em world-space).
	var rim := Polygon2D.new()
	rim.polygon = PackedVector2Array([
		Vector2(-72.0, 0.0),
		Vector2(-52.0, -6.0),
		Vector2(-24.0, -10.0),
		Vector2(0.0, -12.0),
		Vector2(24.0, -10.0),
		Vector2(52.0, -6.0),
		Vector2(72.0, 0.0),
		Vector2(52.0, 6.0),
		Vector2(24.0, 10.0),
		Vector2(0.0, 12.0),
		Vector2(-24.0, 10.0),
		Vector2(-52.0, 6.0)
	])
	rim.color = Color(0.06, 0.06, 0.06, 1.0)
	add_child(rim)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(140.0, 40.0)
	shape.shape = rect
	shape.position = Vector2(0.0, 4.0)
	add_child(shape)


func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		emit_signal("player_entered_crater")
