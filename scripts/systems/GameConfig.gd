extends Node

const SETTINGS_PATH: String = "user://settings.cfg"

const DIFF_EASY: int = 0
const DIFF_NORMAL: int = 1
const DIFF_HARD: int = 2

var difficulty: int = DIFF_NORMAL
var master_volume: float = 0.8
var brightness: float = 1.0
var language: String = "pt"

var selected_start_phase: int = 1
var has_run_state: bool = false
var run_state: Dictionary = {}


func _ready() -> void:
	load_settings()
	apply_audio()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		return

	difficulty = int(cfg.get_value("game", "difficulty", DIFF_NORMAL))
	master_volume = float(cfg.get_value("audio", "master_volume", 0.8))
	brightness = float(cfg.get_value("video", "brightness", 1.0))
	language = String(cfg.get_value("ui", "language", "pt"))

	difficulty = clamp(difficulty, DIFF_EASY, DIFF_HARD)
	master_volume = clamp(master_volume, 0.0, 1.0)
	brightness = clamp(brightness, 0.5, 1.5)
	if language == "":
		language = "pt"


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("ui", "language", language)
	cfg.save(SETTINGS_PATH)


func apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, _to_db(max(master_volume, 0.001)))


func _to_db(v: float) -> float:
	return 20.0 * (log(v) / log(10.0))


func apply_brightness(root: Node) -> void:
	if not root:
		return
	var modulate_node: CanvasModulate = root.get_node_or_null("BrightnessModulate")
	if not modulate_node:
		modulate_node = CanvasModulate.new()
		modulate_node.name = "BrightnessModulate"
		root.add_child(modulate_node)
		root.move_child(modulate_node, 0)

	var b: float = clamp(brightness, 0.5, 1.5)
	modulate_node.color = Color(b, b, b, 1.0)


func difficulty_phase_bonus() -> int:
	match difficulty:
		DIFF_EASY:
			return -1
		DIFF_HARD:
			return 1
		_:
			return 0


func set_run_state(state: Dictionary) -> void:
	run_state = state.duplicate(true)
	has_run_state = true


func clear_run_state() -> void:
	run_state.clear()
	has_run_state = false
