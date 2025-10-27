extends Node
class_name TokenManager

const MAX_TOKENS := 3
var equipped: Array[TokenRes] = []

func add_token(t: TokenRes) -> bool:
	if equipped.size() >= MAX_TOKENS:
		return false
	equipped.append(t)
	return true

# Called every White turn start
func apply_start_of_turn_passives(player, turn_mgr) -> void:
	for t in equipped:
		match t.passive_id:
			"START_TURN_GOLD":
				if player and player.has_method("gain_gold"):
					player.gain_gold(t.passive_value)
			"START_TURN_MOVE":
				if turn_mgr and turn_mgr.has_method("add_extra_moves_bonus"):
					turn_mgr.add_extra_moves_bonus(t.passive_value)
