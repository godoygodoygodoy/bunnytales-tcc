extends Node2D

## Ataque de língua (sapo): estica até o alvo e retrai.
## Texturas ainda podem estar ausentes; usa icon.svg como fallback.

signal finished

@export var segment_texture: Texture2D
@export var tip_texture: Texture2D

@export var extend_speed: float = 1400.0
@export var retract_speed: float = 2000.0
@export var max_length: float = 520.0
@export var min_length: float = 12.0

@export var damage: int = 1

var direction: Vector2 = Vector2.RIGHT
var target_length: float = 220.0

var _current_length: float = 0.0
var _state: String = "extend" # extend | retract
var _hit_done: bool = false

var _segments: Array[Sprite2D] = []
var _segments_root: Node2D
var _tip_sprite: Sprite2D
var _tip_area: Area2D


func _safe_texture(tex: Texture2D) -> Texture2D:
	if tex:
		return tex
	var fallback: Texture2D = load("res://assets/icons/icon.svg")
	return fallback


func _segment_size(tex: Texture2D) -> Vector2:
	var t := _safe_texture(tex)
	if t and t.get_size().x > 0.0:
		return t.get_size()
	return Vector2(32.0, 32.0)


func _ready() -> void:
	direction = direction.normalized() if direction.length() > 0.001 else Vector2.RIGHT
	target_length = clamp(target_length, min_length, max_length)

	_segments_root = Node2D.new()
	add_child(_segments_root)

	_tip_sprite = Sprite2D.new()
	_tip_sprite.texture = _safe_texture(tip_texture)
	_tip_sprite.centered = true
	_tip_sprite.z_index = 5
	_tip_sprite.modulate = Color(0.95, 0.65, 0.75, 1.0)
	add_child(_tip_sprite)

	_tip_area = Area2D.new()
	_tip_area.name = "TipArea"
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	_tip_area.add_child(col)
	_tip_area.body_entered.connect(_on_tip_body_entered)
	add_child(_tip_area)

	_current_length = 0.0
	_update_visuals()


func _process(delta: float) -> void:
	if _state == "extend":
		_current_length = min(_current_length + extend_speed * delta, target_length)
		if is_equal_approx(_current_length, target_length) or _current_length >= target_length - 0.5:
			_state = "retract"
	elif _state == "retract":
		_current_length = max(_current_length - retract_speed * delta, 0.0)
		if _current_length <= 0.5:
			emit_signal("finished")
			queue_free()
			return

	_update_visuals()


func _update_visuals() -> void:
	var seg_tex := _safe_texture(segment_texture)
	var tip_tex := _safe_texture(tip_texture)
	_tip_sprite.texture = tip_tex

	var seg_w := max(_segment_size(seg_tex).x, 8.0)
	# Quantidade de segmentos para cobrir o comprimento atual (deixa o tip no final)
	var available_len := max(_current_length - seg_w * 0.5, 0.0)
	var wanted_count := int(floor(available_len / seg_w))

	# Ajusta pool
	while _segments.size() < wanted_count:
		var s := Sprite2D.new()
		s.texture = seg_tex
		s.centered = true
		s.modulate = Color(0.95, 0.65, 0.75, 1.0)
		s.z_index = 4
		_segments_root.add_child(s)
		_segments.append(s)
	while _segments.size() > wanted_count:
		var last: Sprite2D = _segments.pop_back()
		if is_instance_valid(last):
			last.queue_free()

	# Posiciona segmentos
	var angle := direction.angle()
	for i in range(_segments.size()):
		var dist := (float(i) + 0.5) * seg_w
		var pos := direction * dist
		var s: Sprite2D = _segments[i]
		s.texture = seg_tex
		s.position = pos
		s.rotation = angle

	# Tip no final
	_tip_sprite.position = direction * _current_length
	_tip_sprite.rotation = angle
	_tip_area.position = _tip_sprite.position


func _on_tip_body_entered(body: Node) -> void:
	if _hit_done:
		return
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_hit_done = true
