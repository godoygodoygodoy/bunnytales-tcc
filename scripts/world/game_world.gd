extends Node2D

## Gerencia o mundo continuo com fases, checkpoints, loja, spawn e finais.

const GROUND_Y        : float = 310.0   # Y de spawn (acima do chão em y=384)
const DECOR_INTERVAL  : float = 2.5
const CHECKPOINT_XS := [900.0, 2300.0, 3700.0]
const PHASE_CHOICE_XS := [1200.0, 2600.0, 4200.0]

var decor_timer : float = 0.0

var player: CharacterBody2D = null
var _hud: Node = null

var _ability_system: Node
var _xp_system: Node
var _shop_system: Node
var _level_manager: Node
var _ending_manager: Node
var _enemy_spawner: Node2D

var _active_checkpoint: Area2D = null
var _player_in_checkpoint: bool = false
var _shop_open: bool = false
var _choice_pending: bool = false
var _final_resolved: bool = false

var fallen_wood_tex  = preload("res://assets/textures/world/fallen_wood.png")
var grass_tex        = preload("res://assets/textures/world/grass.png")
var grass1_tex       = preload("res://assets/textures/world/grass1.png")


func _ready() -> void:
	player = get_node_or_null("CharacterBody2D2")
	_hud   = get_node_or_null("HUDLayer")
	if not player:
		return

	_init_systems()
	_create_checkpoints()
	_connect_hud()
	_show_message("Chegue aos checkpoints e use F para abrir a loja.", 4.0)

	for i in range(4):
		var side := 1 if i % 2 == 0 else -1
		_enemy_spawner.spawn_enemy(Vector2(
			player.global_position.x + side * (400.0 + i * 220.0),
			GROUND_Y
		), "melee" if i < 2 else "ranged")

	for i in range(20):
		_spawn_decoration(player.global_position.x + randf_range(-1200.0, 1200.0))


func _init_systems() -> void:
	_ability_system = load("res://scripts/systems/AbilitySystem.gd").new()
	_xp_system = load("res://scripts/systems/XPSystem.gd").new()
	_shop_system = load("res://scripts/systems/ShopSystem.gd").new()
	_level_manager = load("res://scripts/systems/LevelManager.gd").new()
	_ending_manager = load("res://scripts/systems/EndingManager.gd").new()
	_enemy_spawner = load("res://scripts/world/EnemySpawner.gd").new()

	add_child(_ability_system)
	add_child(_xp_system)
	add_child(_shop_system)
	add_child(_level_manager)
	add_child(_ending_manager)
	add_child(_enemy_spawner)

	if _ability_system.unlocked_attacks.has("special"):
		_ability_system.unlocked_attacks["special"] = false

	_enemy_spawner.setup(player)
	_enemy_spawner.ground_y = GROUND_Y
	_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)

	player.setup_systems(_ability_system, _xp_system)

	_xp_system.xp_changed.connect(_on_xp_changed)
	_xp_system.score_changed.connect(_on_score_changed)
	_level_manager.phase_changed.connect(_on_phase_changed)
	_level_manager.route_finished.connect(_on_route_finished)
	_shop_system.purchase_succeeded.connect(_on_purchase_succeeded)
	_shop_system.purchase_failed.connect(_on_purchase_failed)


func _connect_hud() -> void:
	if _hud and _hud.has_method("update_xp"):
		_hud.update_xp(0)
	if _hud and _hud.has_method("update_score"):
		_hud.update_score(0)
	if _hud and _hud.has_method("update_phase"):
		_hud.update_phase(1)


func _create_checkpoints() -> void:
	for i in range(CHECKPOINT_XS.size()):
		var cp: Area2D = load("res://scripts/world/Checkpoint.gd").new()
		cp.checkpoint_id = i + 1
		cp.global_position = Vector2(CHECKPOINT_XS[i], GROUND_Y)
		cp.player_entered.connect(_on_checkpoint_player_entered)
		cp.player_exited.connect(_on_checkpoint_player_exited)
		cp.checkpoint_activated.connect(_on_checkpoint_activated)
		add_child(cp)


func _process(delta: float) -> void:
	if not player:
		return

	decor_timer += delta
	if decor_timer >= DECOR_INTERVAL:
		decor_timer = 0.0
		var side := 1 if randf() > 0.5 else -1
		_spawn_decoration(player.global_position.x + side * randf_range(600.0, 1000.0))

	_check_phase_choice_trigger()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if _choice_pending:
		_handle_choice_input(event.keycode)
		return

	if _player_in_checkpoint and event.keycode == KEY_F:
		_toggle_shop()
		return

	if _shop_open:
		_handle_shop_input(event.keycode)


func _check_phase_choice_trigger() -> void:
	if _final_resolved:
		return
	var current_phase: int = _level_manager.current_phase
	if current_phase > 3:
		return
	if _choice_pending:
		return
	if player.global_position.x < PHASE_CHOICE_XS[current_phase - 1]:
		return

	_choice_pending = true
	_show_message("Fase %d: escolha caminho [1], [2] ou [3]." % current_phase)


func _handle_choice_input(keycode: Key) -> void:
	var choice := -1
	if keycode == KEY_1:
		choice = 0
	elif keycode == KEY_2:
		choice = 1
	elif keycode == KEY_3:
		choice = 2

	if choice == -1:
		return

	_choice_pending = false
	if _level_manager.choose_path(choice):
		_enemy_spawner.spawn_wave_for_path(choice)
		_show_message("Caminho %d confirmado. Nova onda de inimigos!" % (choice + 1), 2.0)


func _toggle_shop() -> void:
	_shop_open = not _shop_open
	if _shop_open:
		_show_message("Loja: [1] Especial  [2] Dash  [3] Pulo duplo  [4] HP  [5] Dano")
	else:
		_show_message("Loja fechada.", 1.0)


func _handle_shop_input(keycode: Key) -> void:
	var item_id := ""
	if keycode == KEY_1:
		item_id = "unlock_special"
	elif keycode == KEY_2:
		item_id = "unlock_dash"
	elif keycode == KEY_3:
		item_id = "unlock_double_jump"
	elif keycode == KEY_4:
		item_id = "increase_max_hp"
	elif keycode == KEY_5:
		item_id = "increase_damage"

	if item_id == "":
		return

	_shop_system.try_purchase(item_id, _xp_system, player, _ability_system)


func _spawn_decoration(x: float) -> void:
	var decor := Sprite2D.new()

	var rand := randf()
	if rand < 0.15:
		decor.texture = fallen_wood_tex
		decor.scale = Vector2(randf_range(2.0, 3.5), randf_range(2.0, 3.5))
		decor.position = Vector2(x, 360.0)
		decor.z_index = 1
	elif rand < 0.6:
		decor.texture = grass_tex
		decor.scale = Vector2(randf_range(2.5, 4.0), randf_range(2.5, 4.0))
		decor.position = Vector2(x, 375.0)
		decor.z_index = 1
	else:
		decor.texture = grass1_tex
		decor.scale = Vector2(randf_range(2.5, 4.0), randf_range(2.5, 4.0))
		decor.position = Vector2(x, 375.0)
		decor.z_index = 1

	add_child(decor)


func _on_enemy_spawned(enemy: CharacterBody2D) -> void:
	if enemy and enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(xp: int) -> void:
	_xp_system.add_xp(xp)


func _on_xp_changed(new_xp: int) -> void:
	if _hud and _hud.has_method("update_xp"):
		_hud.update_xp(new_xp)


func _on_score_changed(new_score: int) -> void:
	if _hud and _hud.has_method("update_score"):
		_hud.update_score(new_score)


func _on_phase_changed(new_phase: int) -> void:
	_enemy_spawner.set_phase(new_phase)
	if _hud and _hud.has_method("update_phase"):
		_hud.update_phase(new_phase)


func _on_route_finished(paths: Array) -> void:
	if _final_resolved:
		return
	_final_resolved = true
	var ending: Dictionary = _ending_manager.resolve_ending(paths)
	_show_message("%s: %s" % [ending.title, ending.description])


func _on_checkpoint_activated(checkpoint: Area2D) -> void:
	_active_checkpoint = checkpoint
	_show_message("Checkpoint %d ativo." % checkpoint.checkpoint_id, 1.5)


func _on_checkpoint_player_entered(checkpoint: Area2D) -> void:
	_active_checkpoint = checkpoint
	_player_in_checkpoint = true
	_show_message("Checkpoint %d: pressione F para loja." % checkpoint.checkpoint_id)


func _on_checkpoint_player_exited(_checkpoint: Area2D) -> void:
	_player_in_checkpoint = false
	_shop_open = false
	_show_message("", 0.0)


func _on_purchase_succeeded(item_id: String, cost: int) -> void:
	_show_message("Compra realizada: %s (-%d XP)." % [item_id, cost], 1.6)


func _on_purchase_failed(_item_id: String, reason: String) -> void:
	_show_message("Compra falhou: %s." % reason, 1.6)


func _show_message(text: String, duration: float = 0.0) -> void:
	if _hud and _hud.has_method("show_message"):
		_hud.show_message(text, duration)
