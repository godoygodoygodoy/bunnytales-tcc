extends StaticBody2D

## Chão infinito: sprites visuais + WorldBoundaryShape2D para colisão
@export var tile_scale: Vector2 = Vector2(4.0, 4.0)  # escala visual de cada tile
@export var tiles_visible: int = 30                   # tiles gerados ao redor do jogador
@export var ground_y: float = 384.0                   # posição Y do topo do chão na cena

var tile_width: float = 96.0
var player: CharacterBody2D
var sprite_tiles: Array[Sprite2D] = []
var ground_texture: Texture2D

func _ready() -> void:
	ground_texture = load("res://assets/textures/world/ground.png")
	if ground_texture:
		tile_width = float(ground_texture.get_width()) * tile_scale.x

	player = get_parent().get_node_or_null("CharacterBody2D2")

	# Colisão infinita: WorldBoundaryShape2D age como um plano infinito
	var col := CollisionShape2D.new()
	var shape := WorldBoundaryShape2D.new()
	shape.normal = Vector2(0, -1)
	shape.distance = -ground_y
	col.shape = shape
	add_child(col)

	# Pool de sprites visuais
	for i in range(tiles_visible * 2 + 2):
		var sprite := Sprite2D.new()
		sprite.texture = ground_texture
		sprite.centered = false
		sprite.scale = tile_scale
		sprite.z_index = 0
		add_child(sprite)
		sprite_tiles.append(sprite)

	_place_tiles()

func _process(_delta: float) -> void:
	_place_tiles()

func _place_tiles() -> void:
	if player == null:
		return
	var px: float = player.global_position.x
	var start_tile: int = int(floor((px - tiles_visible * tile_width) / tile_width))
	for i in range(sprite_tiles.size()):
		sprite_tiles[i].global_position = Vector2((start_tile + i) * tile_width, ground_y)

