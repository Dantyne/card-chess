extends Node
class_name Player

signal gold_changed(new_gold: int)

var gold: int = 0

func gain_gold(n: int) -> void:
	gold += n
	emit_signal("gold_changed", gold)

func spend_gold(n: int) -> bool:
	if gold < n:
		return false
	gold -= n
	emit_signal("gold_changed", gold)
	return true
