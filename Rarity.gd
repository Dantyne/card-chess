extends Node
class_name Rarity

enum Tier { COMMON, RARE, EPIC, LEGENDARY }

static func multiplier(t: int) -> float:
	if t == Tier.COMMON: return 1.0
	if t == Tier.RARE: return 1.5
	if t == Tier.EPIC: return 2.5
	if t == Tier.LEGENDARY: return 4.0
	return 1.0

static func shop_chance_weights() -> Dictionary:
	# total = 100
	return {
		Tier.COMMON: 60,
		Tier.RARE: 25,
		Tier.EPIC: 10,
		Tier.LEGENDARY: 5
	}
