extends Sprite2D

## Background fixo que se ajusta automaticamente ao tamanho da tela

func _ready() -> void:
	if not texture:
		texture = load("res://assets/icons/icon.svg")
	call_deferred("_adjust_scale")

func _adjust_scale() -> void:
	if not texture:
		return
	
	var vp_size : Vector2 = get_viewport().get_visible_rect().size
	var tex_size : Vector2 = Vector2(texture.get_width(), texture.get_height())
	
	# Calcula a escala necessária para cobrir toda a tela
	var scale_x : float = vp_size.x / tex_size.x
	var scale_y : float = vp_size.y / tex_size.y
	
	# Usa a maior escala para garantir que cubra toda a tela
	var final_scale : float = max(scale_x, scale_y)
	scale = Vector2(final_scale, final_scale)
