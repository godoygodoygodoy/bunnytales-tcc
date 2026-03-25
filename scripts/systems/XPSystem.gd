extends Node

signal xp_changed(new_xp: int)
signal score_changed(new_score: int)

var xp: int = 0
var score: int = 0


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	score += amount
	emit_signal("xp_changed", xp)
	emit_signal("score_changed", score)


func can_spend(amount: int) -> bool:
	return amount > 0 and xp >= amount


func spend_xp(amount: int) -> bool:
	if not can_spend(amount):
		return false
	xp -= amount
	emit_signal("xp_changed", xp)
	return true


func export_state() -> Dictionary:
	return {
		"xp": xp,
		"score": score
	}


func import_state(state: Dictionary) -> void:
	xp = int(state.get("xp", xp))
	score = int(state.get("score", score))
	emit_signal("xp_changed", xp)
	emit_signal("score_changed", score)
