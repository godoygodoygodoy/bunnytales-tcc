extends Area2D

signal checkpoint_activated(checkpoint: Area2D)
signal player_entered(checkpoint: Area2D)
signal player_exited(checkpoint: Area2D)

@export var checkpoint_id: int = 0

var is_active: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _build_visual() -> void:
	var marker := ColorRect.new()
	marker.size = Vector2(48.0, 96.0)
	marker.position = Vector2(-24.0, -96.0)
	marker.color = Color(0.2, 0.9, 0.6, 0.35)
	add_child(marker)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80.0, 120.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -60.0)
	add_child(shape)


func activate_for(player: Node) -> void:
	if is_active:
		return
	is_active = true
	if player and player.has_method("set_checkpoint"):
		player.set_checkpoint(global_position)
	emit_signal("checkpoint_activated", self)


func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		emit_signal("player_entered", self)
		activate_for(body)


func _on_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		emit_signal("player_exited", self)
