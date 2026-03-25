extends CanvasLayer

## HUD – vida, ícones de ataque com dimming e pontuação

const SLOT_SIZE  : float = 64.0
const SLOT_GAP   : float = 14.0
const BAR_BOTTOM : float = 28.0

# Cooldowns máximos (espelham as constantes do player)
const CD_MAX := { "Q": 20.0, "E": 0.5, "R": 1.5 }

var _hp_label    : Label
var _score_label : Label
var _xp_label    : Label
var _phase_label : Label
var _message_label : Label
var _player      : Node = null
var _slots       := {}          # key -> TextureRect
var _root        : Control
var _built       : bool = false


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	# Adiar o build para garantir que o viewport já tem tamanho correto
	call_deferred("_build_ui")


func _build_ui() -> void:
	_built = true
	var vp : Vector2 = get_viewport().get_visible_rect().size

	# ── Painel HP / Score / XP / Fase (canto superior esquerdo) ───────────
	var top_bg := ColorRect.new()
	top_bg.color    = Color(0.0, 0.0, 0.0, 0.55)
	top_bg.size     = Vector2(280.0, 92.0)
	top_bg.position = Vector2(8.0, 8.0)
	_root.add_child(top_bg)

	_hp_label = _label(Vector2(16.0, 12.0), 20)
	_hp_label.text = "HP: ♥♥♥♥♥"
	_score_label = _label(Vector2(16.0, 38.0), 14)
	_score_label.text = "Score: 0"
	_xp_label = _label(Vector2(16.0, 58.0), 14)
	_xp_label.text = "XP: 0"
	_phase_label = _label(Vector2(170.0, 58.0), 14)
	_phase_label.text = "Fase: 1"

	# Icones de ataque (centralizados no rodape)
	var tex_q : Texture2D = load("res://assets/textures/ui/power_bar_galaxy.png")
	var tex_d : Texture2D = load("res://assets/textures/ui/power_bar.png")
	var keys_list : Array = ["Q", "E", "R"]
	var textures := { "Q": tex_q, "E": tex_d, "R": tex_d }

	var n : int = keys_list.size()
	var total_w : float = n * SLOT_SIZE + (n - 1) * SLOT_GAP
	var start_x : float = (vp.x - total_w) / 2.0
	var icon_y : float = vp.y - SLOT_SIZE - BAR_BOTTOM - 5.0

	for i in range(n):
		var key  : String = keys_list[i]
		var sx   : float  = start_x + i * (SLOT_SIZE + SLOT_GAP)

		var icon := TextureRect.new()
		icon.texture      = textures[key]
		icon.size         = Vector2(SLOT_SIZE, SLOT_SIZE)
		icon.position     = Vector2(sx, icon_y)
		icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		_root.add_child(icon)
		_slots[key] = icon

		# Rótulo da tecla centralizado abaixo do ícone
		var klbl := _label(Vector2(sx, icon_y + SLOT_SIZE + 3.0), 13)
		klbl.custom_minimum_size.x = SLOT_SIZE
		klbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		klbl.text = "[%s]" % key
		klbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

	# ── Dica de controles ──────────────────────────────────────────────────
	var hint := _label(Vector2(8.0, vp.y - 14.0), 10)
	hint.text = "WASD mover | Shift dash | Q especial | E melee | R tiro | F loja"
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.65))

	_message_label = _label(Vector2(300.0, 18.0), 13)
	_message_label.text = ""
	_message_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.75))


# ── Label helper ────────────────────────────────────────────────────────────
func _label(pos: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	_root.add_child(lbl)
	return lbl


# ── Loop principal ───────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if not _built or _slots.is_empty():
		return

	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return

	# HP
	var hp     : int = int(_player.get("hp"))
	var hp_max : int = int(_player.get("HP_MAX"))
	if hp >= 0 and hp_max > 0:
		var hearts := ""
		for i in range(hp_max):
			hearts += "♥" if i < hp else "♡"
		_hp_label.text     = "HP: " + hearts
		_hp_label.modulate = Color(1.0, 0.3, 0.3) if hp <= 1 else Color.WHITE

	# Cooldowns
	_update_slot("Q", _player.get("galaxy_attack_cooldown_timer"))
	_update_slot("E", _player.get("melee_cooldown_timer"))
	_update_slot("R", _player.get("shot_cooldown_timer"))


func _update_slot(key: String, cd: float) -> void:
	var icon   : TextureRect = _slots[key]
	var max_cd : float       = CD_MAX[key]
	if cd > 0.0:
		# ratio 1.0 = recém usado (escuro) → 0.0 = prestes a liberar (quase normal)
		var brightness : float = lerp(1.0, 0.18, cd / max_cd)
		icon.modulate = Color(brightness, brightness, brightness, 1.0)
	else:
		icon.modulate = Color.WHITE


func update_score(new_score: int) -> void:
	if _score_label:
		_score_label.text = "Score: %d" % new_score


func update_xp(new_xp: int) -> void:
	if _xp_label:
		_xp_label.text = "XP: %d" % new_xp


func update_phase(phase: int) -> void:
	if _phase_label:
		_phase_label.text = "Fase: %d" % phase


func show_message(text: String, duration: float = 0.0) -> void:
	if not _message_label:
		return
	_message_label.text = text
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(self) and _message_label.text == text:
			_message_label.text = ""
