extends Node

signal ending_resolved(ending_id: int, title: String, description: String)


func resolve_ending(paths: Array[int]) -> Dictionary:
	var ending := _compute_ending(paths)
	emit_signal("ending_resolved", ending.id, ending.title, ending.description)
	return ending


func _compute_ending(paths: Array[int]) -> Dictionary:
	if paths.size() < 3:
		return {
			"id": 0,
			"title": "Final incompleto",
			"description": "Conclua as tres fases para liberar um final."
		}

	var sum_paths: int = 0
	var risky_count: int = 0
	for p in paths:
		sum_paths += p
		if p == 2:
			risky_count += 1

	if risky_count >= 2:
		return {
			"id": 3,
			"title": "Final Ruptura",
			"description": "As escolhas agressivas quebram o equilibrio do vale."
		}
	if sum_paths <= 1:
		return {
			"id": 1,
			"title": "Final Aurora",
			"description": "O coelho protegeu a floresta e manteve o ciclo vivo."
		}
	return {
		"id": 2,
		"title": "Final Eclipse",
		"description": "O caminho foi utilitario: sobrevivencia com sacrificios."
	}
