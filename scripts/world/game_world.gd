extends Node2D

## Gerencia o mundo continuo com fases e loja de transicao entre fases.

const GROUND_Y        : float = 310.0   # Y de spawn (acima do chão em y=384)
const DECOR_INTERVAL  : float = 2.5
const PHASE1_SCORE_TARGET: int = 1200

var decor_timer : float = 0.0

var player: CharacterBody2D = null
var _hud: Node = null

var _ability_system: Node
var _xp_system: Node
var _shop_system: Node
var _level_manager: Node
var _ending_manager: Node
var _enemy_spawner: Node2D
var _cfg: Node = null

var _final_resolved: bool = false
var _phase_completed: bool = false
var _is_transitioning: bool = false
var _phase_crater: Area2D = null

var fallen_wood_tex: Texture2D
var grass_tex: Texture2D
var grass1_tex: Texture2D


func _safe_texture(path: String) -> Texture2D:
	var tex: Texture2D = load(path)
	if tex:
		return tex
	return load("res://assets/icons/icon.svg")


func _ready() -> void:
	_cfg = get_node_or_null("/root/GameConfig")
	if _cfg and _cfg.has_method("apply_brightness"):
		_cfg.apply_brightness(self)
	player = get_node_or_null("CharacterBody2D2")
	_hud   = get_node_or_null("HUDLayer")
	if not player:
		return

	fallen_wood_tex = _safe_texture("res://assets/textures/world/fallen_wood.png")
	grass_tex = _safe_texture("res://assets/textures/world/grass.png")
	grass1_tex = _safe_texture("res://assets/textures/world/grass1.png")

	_init_systems()
	_connect_hud()
	_show_message("Fase 1 (Pontos): alcance %d pontos para abrir a loja de transicao." % PHASE1_SCORE_TARGET, 4.0)

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
	if _cfg and _cfg.has_method("difficulty_phase_bonus"):
		_enemy_spawner.set_difficulty_bonus(_cfg.difficulty_phase_bonus())
	_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)

	var restored: bool = false
	if _cfg and bool(_cfg.get("has_run_state")):
		var rs: Dictionary = _cfg.get("run_state")
		if rs.has("ability"):
			_ability_system.import_state(rs["ability"])
		if rs.has("xp"):
			_xp_system.import_state(rs["xp"])
		if rs.has("player"):
			player.import_progress_state(rs["player"])
		var phase_from_state: int = int(rs.get("phase", 1))
		_level_manager.start_from_phase(phase_from_state)
		if _cfg.has_method("clear_run_state"):
			_cfg.clear_run_state()
		restored = true

	if not restored:
		_level_manager.start_from_phase(1)

	player.setup_systems(_ability_system, _xp_system)

	_xp_system.xp_changed.connect(_on_xp_changed)
	_xp_system.score_changed.connect(_on_score_changed)
	_level_manager.phase_changed.connect(_on_phase_changed)
	_level_manager.route_finished.connect(_on_route_finished)


func _connect_hud() -> void:
	if _hud and _hud.has_method("update_xp"):
		_hud.update_xp(_xp_system.xp)
	if _hud and _hud.has_method("update_score"):
		_hud.update_score(_xp_system.score)
	if _hud and _hud.has_method("update_phase"):
		_hud.update_phase(_level_manager.current_phase)


func _process(delta: float) -> void:
	if not player:
		return

	decor_timer += delta
	if decor_timer >= DECOR_INTERVAL:
		decor_timer = 0.0
		var side := 1 if randf() > 0.5 else -1
		_spawn_decoration(player.global_position.x + side * randf_range(600.0, 1000.0))

	_check_phase_goal()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	# Atalho de teste: Ctrl + Shift + R cria a cratera manualmente.
	if event.keycode == KEY_R and event.ctrl_pressed and event.shift_pressed:
		_spawn_test_crater()
		get_viewport().set_input_as_handled()
		return


func _check_phase_goal() -> void:
	if _phase_completed or _is_transitioning:
		return

	var current_phase: int = _level_manager.current_phase
	if current_phase == 1 and _xp_system.score >= PHASE1_SCORE_TARGET:
		_phase_completed = true
		_spawn_phase_crater()
		_show_message("Fase 1 concluida! Uma cratera surgiu ao lado. Pule nela para ir a loja.")


func _spawn_phase_crater() -> void:
	if _phase_crater:
		return
	_phase_crater = load("res://scripts/world/PhaseCrater.gd").new()
	_phase_crater.global_position = Vector2(player.global_position.x + 170.0, 384.0)
	_phase_crater.player_entered_crater.connect(_on_player_entered_phase_crater)
	add_child(_phase_crater)


func _spawn_test_crater() -> void:
	if _phase_crater and is_instance_valid(_phase_crater):
		_phase_crater.queue_free()
	_phase_crater = null
	_spawn_phase_crater()
	_show_message("Cratera de teste criada.", 1.2)

func _spawn_decoration(x: float) -> void:
	var decor := Sprite2D.new()

	var rand := randf()
	if rand < 0.08:
		decor.texture = fallen_wood_tex
		decor.scale = Vector2(randf_range(2.4, 3.0), randf_range(2.4, 3.0))
		decor.position = Vector2(x, 286.0)
		decor.z_index = 5
	elif rand < 0.66:
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
	_phase_completed = false

	if new_phase == 1:
		_show_message("Fase 1 (Pontos): alcance %d pontos para transicao." % PHASE1_SCORE_TARGET, 3.0)
	elif new_phase == 2:
		_show_message("Fase 2 (Estrategia) indisponivel por enquanto.")
	elif new_phase == 3:
		_show_message("Fase 3 (Tempo) indisponivel por enquanto.")


func _on_route_finished(paths: Array) -> void:
	if _final_resolved:
		return
	_final_resolved = true
	var ending: Dictionary = _ending_manager.resolve_ending(paths)
	var combo_key: String = _level_manager.get_combination_key()
	_show_message("Rota %s | %s: %s" % [combo_key, ending.title, ending.description])


func _show_message(text: String, duration: float = 0.0) -> void:
	if _hud and _hud.has_method("show_message"):
		_hud.show_message(text, duration)


func _on_player_entered_phase_crater() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if _cfg and _cfg.has_method("set_run_state"):
		_cfg.set_run_state({
			"ability": _ability_system.export_state(),
			"xp": _xp_system.export_state(),
			"player": player.export_progress_state(),
			"phase": _level_manager.current_phase
		})
	get_tree().change_scene_to_file("res://scenes/shop_world.tscn")
