extends Node

signal attack_unlocked(attack_name: String)
signal movement_unlocked(movement_name: String)
signal strength_changed(multiplier: float)

const SACRIFICE_HP_RATIO: float = 0.10
const SACRIFICE_STRENGTH_BONUS: float = 0.10
const SACRIFICE_DURATION: float = 8.0

var unlocked_attacks := {
	"melee": true,
	"projectile": true,
	"special": true
}

var unlocked_movements := {
	"double_jump": true,
	"dash": true
}

var permanent_damage_bonus: float = 0.0
var temporary_damage_bonus: float = 0.0
var _buff_timer: float = 0.0


func _process(delta: float) -> void:
	if _buff_timer > 0.0:
		_buff_timer = max(_buff_timer - delta, 0.0)
		if _buff_timer == 0.0 and temporary_damage_bonus > 0.0:
			temporary_damage_bonus = 0.0
			emit_signal("strength_changed", get_damage_multiplier())


func unlock_attack(attack_name: String) -> bool:
	if unlocked_attacks.get(attack_name, null) == null:
		return false
	if unlocked_attacks[attack_name]:
		return false
	unlocked_attacks[attack_name] = true
	emit_signal("attack_unlocked", attack_name)
	return true


func unlock_movement(movement_name: String) -> bool:
	if unlocked_movements.get(movement_name, null) == null:
		return false
	if unlocked_movements[movement_name]:
		return false
	unlocked_movements[movement_name] = true
	emit_signal("movement_unlocked", movement_name)
	return true


func is_attack_unlocked(attack_name: String) -> bool:
	return unlocked_attacks.get(attack_name, false)


func is_movement_unlocked(movement_name: String) -> bool:
	return unlocked_movements.get(movement_name, false)


func add_permanent_damage_bonus(value: float) -> void:
	permanent_damage_bonus = max(permanent_damage_bonus + value, 0.0)
	emit_signal("strength_changed", get_damage_multiplier())


func get_damage_multiplier() -> float:
	return 1.0 + permanent_damage_bonus + temporary_damage_bonus


func try_activate_sacrifice_buff(player: Node) -> bool:
	if not is_attack_unlocked("special"):
		return false
	if not player or not player.has_method("try_spend_hp_ratio"):
		return false
	if not player.try_spend_hp_ratio(SACRIFICE_HP_RATIO):
		return false

	temporary_damage_bonus = SACRIFICE_STRENGTH_BONUS
	_buff_timer = SACRIFICE_DURATION
	emit_signal("strength_changed", get_damage_multiplier())
	return true
