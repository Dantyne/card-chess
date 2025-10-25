# Player.gd
extends Node

var gold: int = 3  # starting gold

func gain_gold(amount: int) -> void:
	gold += amount
	update_gold_display()

func spend_gold(cost: int) -> bool:
	if gold >= cost:
		gold -= cost
		update_gold_display()
		return true
	return false

func update_gold_display() -> void:
	# If your UI node exists, this updates it dynamically
	if has_node("/root/Game/UI"):
		var ui = get_node("/root/Game/UI")
		ui.update_gold_display(gold)
