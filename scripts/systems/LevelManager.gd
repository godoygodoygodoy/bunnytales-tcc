extends Node

signal phase_changed(new_phase: int)
signal path_chosen(phase: int, path_index: int)
signal route_finished(paths: Array)

const PHASE_COUNT: int = 3
const PATHS_PER_PHASE: int = 3

var current_phase: int = 1
var chosen_paths: Array[int] = []

var phase_kinds := {
	1: "pontos",
	2: "estrategia",
	3: "tempo"
}

var phase_available := {
	1: true,
	2: false,
	3: false
}


func choose_path(path_index: int) -> bool:
	if current_phase > PHASE_COUNT:
		return false
	if path_index < 0 or path_index >= PATHS_PER_PHASE:
		return false

	chosen_paths.append(path_index)
	emit_signal("path_chosen", current_phase, path_index)

	if chosen_paths.size() >= PHASE_COUNT:
		emit_signal("route_finished", chosen_paths.duplicate())
		current_phase = PHASE_COUNT + 1
		return true

	current_phase += 1
	emit_signal("phase_changed", current_phase)
	return true


func get_paths() -> Array[int]:
	return chosen_paths.duplicate()


func get_combination_key() -> String:
	if chosen_paths.size() < PHASE_COUNT:
		return "incomplete"
	return "%d-%d-%d" % [chosen_paths[0] + 1, chosen_paths[1] + 1, chosen_paths[2] + 1]


func restore_progress(paths: Array[int], phase: int) -> void:
	chosen_paths = paths.duplicate()
	current_phase = clamp(phase, 1, PHASE_COUNT + 1)
	emit_signal("phase_changed", current_phase)


func start_from_phase(phase: int) -> void:
	current_phase = clamp(phase, 1, PHASE_COUNT)
	chosen_paths.clear()
	emit_signal("phase_changed", current_phase)


func is_phase_available(phase: int) -> bool:
	return bool(phase_available.get(phase, false))


func get_phase_kind(phase: int) -> String:
	return String(phase_kinds.get(phase, "desconhecido"))
