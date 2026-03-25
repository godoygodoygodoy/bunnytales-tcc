extends Area2D

signal player_entered(shop: Area2D)
signal player_exited(shop: Area2D)

@export var shop_id: int = 0


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _build_visual() -> void:
	var stand := ColorRect.new()
	stand.size = Vector2(110.0, 90.0)
	stand.position = Vector2(-55.0, -90.0)
	stand.color = Color(0.2, 0.16, 0.08, 0.92)
	add_child(stand)

	var banner := Label.new()
	banner.text = "SHOP"
	banner.position = Vector2(-24.0, -114.0)
	banner.add_theme_font_size_override("font_size", 18)
	add_child(banner)

	var icon := Sprite2D.new()
	icon.texture = load("res://assets/icons/icon.svg")
	icon.scale = Vector2(0.35, 0.35)
	icon.position = Vector2(0.0, -45.0)
	icon.modulate = Color(1.0, 0.95, 0.5)
	add_child(icon)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(130.0, 120.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -60.0)
	add_child(shape)


func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		emit_signal("player_entered", self)


func _on_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		emit_signal("player_exited", self)
