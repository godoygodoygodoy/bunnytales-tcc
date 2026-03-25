extends Node

signal purchase_succeeded(item_id: String, cost: int)
signal purchase_failed(item_id: String, reason: String)

var catalog := {
	"unlock_special": {"cost": 180, "label": "Desbloquear especial"},
	"unlock_dash": {"cost": 120, "label": "Dash overdrive"},
	"unlock_double_jump": {"cost": 120, "label": "Salto adicional"},
	"increase_max_hp": {"cost": 90, "label": "+1 HP max"},
	"increase_damage": {"cost": 140, "label": "+10% dano permanente"}
}


func get_catalog() -> Dictionary:
	return catalog


func try_purchase(item_id: String, xp_system: Node, player: Node, ability_system: Node) -> bool:
	if not catalog.has(item_id):
		emit_signal("purchase_failed", item_id, "Item inexistente")
		return false

	var cost: int = int(catalog[item_id]["cost"])
	if not xp_system or not xp_system.has_method("spend_xp"):
		emit_signal("purchase_failed", item_id, "Sistema de XP invalido")
		return false

	if not xp_system.spend_xp(cost):
		emit_signal("purchase_failed", item_id, "XP insuficiente")
		return false

	var ok: bool = _apply_item(item_id, player, ability_system)
	if not ok:
		xp_system.add_xp(cost)
		emit_signal("purchase_failed", item_id, "Melhoria ja adquirida")
		return false

	emit_signal("purchase_succeeded", item_id, cost)
	return true


func _apply_item(item_id: String, player: Node, ability_system: Node) -> bool:
	match item_id:
		"unlock_special":
			return ability_system.unlock_attack("special")
		"unlock_dash":
			if player and player.has_method("improve_dash"):
				return player.improve_dash()
		"unlock_double_jump":
			if player and player.has_method("unlock_extra_jump"):
				return player.unlock_extra_jump()
		"increase_max_hp":
			if player and player.has_method("increase_max_hp"):
				player.increase_max_hp(1)
				return true
		"increase_damage":
			ability_system.add_permanent_damage_bonus(0.10)
			return true
	return false
