extends Node
class_name CardManager

var deck: Array[SpellRes] = []
var hand: Array[SpellRes] = []
var discard: Array[SpellRes] = []
var hand_size: int = 3

func draw_to(size: int) -> void:
	while hand.size() < size and deck.size() > 0:
		hand.append(deck.pop_back())

func discard_at(idx: int) -> void:
	if idx >= 0 and idx < hand.size():
		discard.append(hand[idx])
		hand.remove_at(idx)

func can_afford(player: Node, s: SpellRes) -> bool:
	return player.gold >= _price(s)

func pay_and_cast(player: Node, s: SpellRes) -> bool:
	# Cards in hand are already paid for when purchased in the shop.
	# So casting them should not consume gold.
	return true
	
func _price(s: SpellRes) -> int:
	return int(round(s.base_cost * Rarity.multiplier(s.rarity)))
