extends Node2D

const GROUND_Y: float = 310.0

var player: CharacterBody2D = null
var _hud: Node = null
var _cfg: Node = null
var _ability_system: Node
var _xp_system: Node
var _shop_system: Node
var _level_manager: Node

var _shop_open: bool = false
var _player_in_npc: bool = false
var _npc: Area2D


func _ready() -> void:
	_cfg = get_node_or_null("/root/GameConfig")
	if _cfg and _cfg.has_method("apply_brightness"):
		_cfg.apply_brightness(self)

	player = get_node_or_null("CharacterBody2D2")
	_hud = get_node_or_null("HUDLayer")
	if not player:
		return

	_setup_systems()
	_spawn_npc()
	_show_message("Area de transicao. Fale com o personagem (F) para abrir a loja.", 4.0)


func _setup_systems() -> void:
	_ability_system = load("res://scripts/systems/AbilitySystem.gd").new()
	_xp_system = load("res://scripts/systems/XPSystem.gd").new()
	_shop_system = load("res://scripts/systems/ShopSystem.gd").new()
	_level_manager = load("res://scripts/systems/LevelManager.gd").new()
	add_child(_ability_system)
	add_child(_xp_system)
	add_child(_shop_system)
	add_child(_level_manager)

	player.setup_systems(_ability_system, _xp_system)
	_xp_system.xp_changed.connect(_on_xp_changed)
	_shop_system.purchase_succeeded.connect(_on_purchase_succeeded)
	_shop_system.purchase_failed.connect(_on_purchase_failed)

	if _cfg and bool(_cfg.get("has_run_state")):
		var rs: Dictionary = _cfg.get("run_state")
		if rs.has("ability"):
			_ability_system.import_state(rs["ability"])
		if rs.has("xp"):
			_xp_system.import_state(rs["xp"])
		if rs.has("player"):
			player.import_progress_state(rs["player"])
		if rs.has("phase"):
			_level_manager.start_from_phase(int(rs["phase"]))

	if _hud and _hud.has_method("update_xp"):
		_hud.update_xp(_xp_system.xp)
	if _hud and _hud.has_method("update_score"):
		_hud.update_score(_xp_system.score)
	if _hud and _hud.has_method("update_phase"):
		_hud.update_phase(_level_manager.current_phase)


func _spawn_npc() -> void:
	_npc = Area2D.new()
	_npc.global_position = Vector2(420.0, GROUND_Y)
	add_child(_npc)

	var body := ColorRect.new()
	body.size = Vector2(70.0, 120.0)
	body.position = Vector2(-35.0, -120.0)
	body.color = Color(0.6, 0.6, 0.6, 1.0)
	_npc.add_child(body)

	var icon := Sprite2D.new()
	icon.texture = load("res://assets/icons/icon.svg")
	icon.scale = Vector2(0.5, 0.5)
	icon.position = Vector2(0.0, -70.0)
	_npc.add_child(icon)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120.0, 150.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -75.0)
	_npc.add_child(shape)

	_npc.body_entered.connect(_on_npc_body_entered)
	_npc.body_exited.connect(_on_npc_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if event.keycode == KEY_F and _player_in_npc:
		_toggle_shop_menu()
		return

	if not _shop_open:
		return

	if event.keycode == KEY_ENTER:
		_continue_after_shop()
		return

	var item_id := ""
	if event.keycode == KEY_1:
		item_id = "unlock_special"
	elif event.keycode == KEY_2:
		item_id = "unlock_dash"
	elif event.keycode == KEY_3:
		item_id = "unlock_double_jump"
	elif event.keycode == KEY_4:
		item_id = "increase_max_hp"
	elif event.keycode == KEY_5:
		item_id = "increase_damage"

	if item_id != "":
		_shop_system.try_purchase(item_id, _xp_system, player, _ability_system)


func _toggle_shop_menu() -> void:
	_shop_open = not _shop_open
	if _shop_open:
		if _hud and _hud.has_method("show_shop_menu"):
			_hud.show_shop_menu(_xp_system.xp)
		_show_message("Loja aberta: [1..5] comprar | ENTER continuar", 2.0)
	else:
		if _hud and _hud.has_method("hide_shop_menu"):
			_hud.hide_shop_menu()


func _continue_after_shop() -> void:
	var current_phase: int = _level_manager.current_phase
	var next_phase: int = current_phase + 1
	if not _level_manager.is_phase_available(next_phase):
		_show_message("Fase %d (%s) indisponivel. Voltando ao menu." % [next_phase, _level_manager.get_phase_kind(next_phase)], 2.0)
		await get_tree().create_timer(2.1).timeout
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		return

	if _cfg and _cfg.has_method("set_run_state"):
		_cfg.set_run_state({
			"ability": _ability_system.export_state(),
			"xp": _xp_system.export_state(),
			"player": player.export_progress_state(),
			"phase": next_phase
		})
	get_tree().change_scene_to_file("res://scenes/node_2d.tscn")


func _on_npc_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_npc = true
		_show_message("Pressione F para falar e abrir a loja.", 2.0)


func _on_npc_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_npc = false
		if _shop_open:
			_toggle_shop_menu()


func _on_xp_changed(new_xp: int) -> void:
	if _hud and _hud.has_method("update_xp"):
		_hud.update_xp(new_xp)
	if _hud and _hud.has_method("update_shop_xp"):
		_hud.update_shop_xp(new_xp)


func _on_purchase_succeeded(item_id: String, cost: int) -> void:
	_show_message("Compra: %s (-%d XP)." % [item_id, cost], 1.2)


func _on_purchase_failed(_item_id: String, reason: String) -> void:
	_show_message("Compra falhou: %s" % reason, 1.2)


func _show_message(text: String, duration: float = 0.0) -> void:
	if _hud and _hud.has_method("show_message"):
		_hud.show_message(text, duration)
