extends Control

@onready var _title: Label = $MainPanel/Title
@onready var _btn_new_game: Button = $MainPanel/Buttons/NewGame
@onready var _btn_phase_select: Button = $MainPanel/Buttons/PhaseSelect
@onready var _btn_options: Button = $MainPanel/Buttons/Options
@onready var _btn_quit: Button = $MainPanel/Buttons/Quit

@onready var _options_panel: Panel = $OptionsPanel
@onready var _difficulty_opt: OptionButton = $OptionsPanel/VBox/DifficultyRow/DifficultyOption
@onready var _language_opt: OptionButton = $OptionsPanel/VBox/LanguageRow/LanguageOption
@onready var _volume_slider: HSlider = $OptionsPanel/VBox/VolumeRow/VolumeSlider
@onready var _brightness_slider: HSlider = $OptionsPanel/VBox/BrightnessRow/BrightnessSlider
@onready var _btn_apply: Button = $OptionsPanel/VBox/Buttons/Apply
@onready var _btn_back_options: Button = $OptionsPanel/VBox/Buttons/Back

@onready var _phase_panel: Panel = $PhasePanel
@onready var _btn_phase_1: Button = $PhasePanel/VBox/PhaseButtons/Phase1
@onready var _btn_phase_2: Button = $PhasePanel/VBox/PhaseButtons/Phase2
@onready var _btn_phase_3: Button = $PhasePanel/VBox/PhaseButtons/Phase3
@onready var _btn_back_phase: Button = $PhasePanel/VBox/Back

var _cfg: Node = null

var _texts := {
	"pt": {
		"title": "BUNNY AND TALES",
		"new_game": "Novo Jogo",
		"phase_select": "Escolher Fase",
		"options": "Opcoes",
		"quit": "Sair",
		"options_title": "Configuracoes",
		"difficulty": "Dificuldade",
		"volume": "Volume",
		"brightness": "Brilho",
		"language": "Idioma",
		"apply": "Aplicar",
		"back": "Voltar",
		"phase_title": "Selecione a Fase Inicial"
	},
	"en": {
		"title": "BUNNY AND TALES",
		"new_game": "New Game",
		"phase_select": "Select Phase",
		"options": "Options",
		"quit": "Quit",
		"options_title": "Settings",
		"difficulty": "Difficulty",
		"volume": "Volume",
		"brightness": "Brightness",
		"language": "Language",
		"apply": "Apply",
		"back": "Back",
		"phase_title": "Select Starting Phase"
	},
	"es": {
		"title": "BUNNY AND TALES",
		"new_game": "Nuevo Juego",
		"phase_select": "Elegir Fase",
		"options": "Opciones",
		"quit": "Salir",
		"options_title": "Configuracion",
		"difficulty": "Dificultad",
		"volume": "Volumen",
		"brightness": "Brillo",
		"language": "Idioma",
		"apply": "Aplicar",
		"back": "Volver",
		"phase_title": "Selecciona la Fase Inicial"
	}
}


func _ready() -> void:
	_cfg = get_node_or_null("/root/GameConfig")
	if _cfg and _cfg.has_method("apply_audio"):
		_cfg.apply_audio()
	if _cfg and _cfg.has_method("apply_brightness"):
		_cfg.apply_brightness(self)

	_setup_options_controls()
	_connect_buttons()
	_refresh_texts()
	_options_panel.visible = false
	_phase_panel.visible = false
	_btn_phase_2.disabled = true
	_btn_phase_3.disabled = true
	_btn_phase_2.tooltip_text = "Indisponivel por enquanto"
	_btn_phase_3.tooltip_text = "Indisponivel por enquanto"


func _setup_options_controls() -> void:
	_difficulty_opt.clear()
	_difficulty_opt.add_item("Easy", 0)
	_difficulty_opt.add_item("Normal", 1)
	_difficulty_opt.add_item("Hard", 2)
	if _cfg:
		_difficulty_opt.select(int(_cfg.get("difficulty")))

	_language_opt.clear()
	_language_opt.add_item("Portugues", 0)
	_language_opt.add_item("English", 1)
	_language_opt.add_item("Espanol", 2)
	var lang := "pt"
	if _cfg:
		lang = String(_cfg.get("language"))
	match lang:
		"en":
			_language_opt.select(1)
		"es":
			_language_opt.select(2)
		_:
			_language_opt.select(0)

	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.01
	if _cfg:
		_volume_slider.value = float(_cfg.get("master_volume"))

	_brightness_slider.min_value = 0.5
	_brightness_slider.max_value = 1.5
	_brightness_slider.step = 0.01
	if _cfg:
		_brightness_slider.value = float(_cfg.get("brightness"))


func _connect_buttons() -> void:
	_btn_new_game.pressed.connect(_on_new_game)
	_btn_phase_select.pressed.connect(_on_open_phase_select)
	_btn_options.pressed.connect(_on_open_options)
	_btn_quit.pressed.connect(_on_quit)

	_btn_apply.pressed.connect(_on_apply_options)
	_btn_back_options.pressed.connect(_on_back_options)

	_btn_phase_1.pressed.connect(_on_select_phase_1)
	_btn_phase_2.pressed.connect(_on_select_phase_2)
	_btn_phase_3.pressed.connect(_on_select_phase_3)
	_btn_back_phase.pressed.connect(_on_back_phase)


func _lang_text(key: String) -> String:
	var lang: String = "pt"
	if _cfg:
		lang = String(_cfg.get("language"))
	if not _texts.has(lang):
		lang = "pt"
	return String(_texts[lang].get(key, key))


func _refresh_texts() -> void:
	_title.text = _lang_text("title")
	_btn_new_game.text = _lang_text("new_game")
	_btn_phase_select.text = _lang_text("phase_select")
	_btn_options.text = _lang_text("options")
	_btn_quit.text = _lang_text("quit")
	$OptionsPanel/VBox/Title.text = _lang_text("options_title")
	$OptionsPanel/VBox/DifficultyRow/DifficultyLabel.text = _lang_text("difficulty")
	$OptionsPanel/VBox/VolumeRow/VolumeLabel.text = _lang_text("volume")
	$OptionsPanel/VBox/BrightnessRow/BrightnessLabel.text = _lang_text("brightness")
	$OptionsPanel/VBox/LanguageRow/LanguageLabel.text = _lang_text("language")
	_btn_apply.text = _lang_text("apply")
	_btn_back_options.text = _lang_text("back")
	$PhasePanel/VBox/Title.text = _lang_text("phase_title")
	_btn_phase_1.text = "Fase 1 - Pontos (disponivel)"
	_btn_phase_2.text = "Fase 2 - Estrategia (indisponivel)"
	_btn_phase_3.text = "Fase 3 - Tempo (indisponivel)"
	_btn_back_phase.text = _lang_text("back")


func _on_apply_options() -> void:
	if not _cfg:
		return

	_cfg.set("difficulty", int(_difficulty_opt.get_selected_id()))
	_cfg.set("master_volume", float(_volume_slider.value))
	_cfg.set("brightness", float(_brightness_slider.value))

	match _language_opt.selected:
		1:
			_cfg.set("language", "en")
		2:
			_cfg.set("language", "es")
		_:
			_cfg.set("language", "pt")

	if _cfg.has_method("save_settings"):
		_cfg.save_settings()
	if _cfg.has_method("apply_audio"):
		_cfg.apply_audio()
	if _cfg.has_method("apply_brightness"):
		_cfg.apply_brightness(self)
	_refresh_texts()


func _on_new_game() -> void:
	_start_from_phase(1)


func _start_from_phase(phase: int) -> void:
	if _cfg:
		# TEMPORARIO: todas as fases iniciam no mesmo estado (fase 1).
		_cfg.set("selected_start_phase", 1)
	get_tree().change_scene_to_file("res://scenes/node_2d.tscn")


func _on_open_phase_select() -> void:
	_phase_panel.visible = true
	_options_panel.visible = false


func _on_open_options() -> void:
	_options_panel.visible = true
	_phase_panel.visible = false


func _on_quit() -> void:
	get_tree().quit()


func _on_back_options() -> void:
	_options_panel.visible = false


func _on_select_phase_1() -> void:
	_start_from_phase(1)


func _on_select_phase_2() -> void:
	return


func _on_select_phase_3() -> void:
	return


func _on_back_phase() -> void:
	_phase_panel.visible = false
