extends Node2D

signal enemy_spawned(enemy: CharacterBody2D)

@export var auto_spawn: bool = true
@export var spawn_interval: float = 6.0
@export var spawn_distance_min: float = 500.0
@export var spawn_distance_max: float = 850.0
@export var ground_y: float = 310.0

var player: Node2D = null
var current_phase: int = 1
var difficulty_phase_bonus: int = 0
var _spawn_timer: float = 0.0

var EnemyScript = preload("res://scripts/entities/enemy.gd")


func setup(target_player: Node2D) -> void:
	player = target_player


func set_phase(phase: int) -> void:
	current_phase = maxi(1, phase)


func set_difficulty_bonus(bonus: int) -> void:
	difficulty_phase_bonus = clampi(bonus, -1, 2)


func _process(delta: float) -> void:
	if not auto_spawn or not player:
		return

	_spawn_timer += delta
	if _spawn_timer < spawn_interval:
		return

	_spawn_timer = 0.0
	var side := 1.0 if randf() > 0.5 else -1.0
	var spawn_pos := Vector2(
		player.global_position.x + side * randf_range(spawn_distance_min, spawn_distance_max),
		ground_y
	)
	var enemy_type := "melee" if randf() > 0.35 else "ranged"
	spawn_enemy(spawn_pos, enemy_type)


func spawn_enemy(position: Vector2, enemy_type: String = "melee") -> CharacterBody2D:
	var enemy: CharacterBody2D = EnemyScript.new()
	enemy.global_position = position
	if enemy.has_method("configure_for_phase"):
		var effective_phase: int = maxi(1, current_phase + difficulty_phase_bonus)
		enemy.configure_for_phase(effective_phase, enemy_type)
	add_child(enemy)
	emit_signal("enemy_spawned", enemy)
	return enemy


func spawn_wave_for_path(path_index: int) -> void:
	if not player:
		return
	var count: int = 2 + current_phase + path_index
	for i in range(count):
		var side := 1.0 if i % 2 == 0 else -1.0
		var spawn_pos := Vector2(
			player.global_position.x + side * (320.0 + i * 120.0),
			ground_y
		)
		var enemy_type := "melee"
		if path_index == 2 or (path_index == 1 and i % 2 == 1):
			enemy_type = "ranged"
		spawn_enemy(spawn_pos, enemy_type)
