extends Node
class_name ContentDB
@onready var rarity := Rarity

var spells: Array[SpellRes] = []
var pieces: Array[PieceRes] = []
var tokens: Array[TokenRes] = []

func _ready() -> void:
	# In a real project, load .tres files from folders.
	# For now, create a few in code.

	var smite := SpellRes.new()
	smite.type_name = "Spell"; smite.id="spell_smite"; smite.name="Smite"
	smite.description="Destroy a black piece."
	smite.rarity = rarity.Tier.RARE; smite.base_cost = 3
	spells.append(smite)

	var extra := SpellRes.new()
	extra.type_name="Spell"; extra.id="spell_extra_move"; extra.name="Extra Move"
	extra.description="Gain +1 move this turn."
	extra.rarity = rarity.Tier.COMMON; extra.base_cost = 2
	spells.append(extra)

	var pawn := PieceRes.new()
	pawn.type_name="Piece"; pawn.id="piece_pawn"; pawn.name="Pawn"
	pawn.description="Consumable: deploy a Pawn on your half."
	pawn.rarity = rarity.Tier.COMMON; pawn.base_cost = 2; pawn.piece_code = 1
	pieces.append(pawn)

	var rook := PieceRes.new()
	rook.type_name="Piece"; rook.id="piece_rook"; rook.name="Rook"
	rook.description="Consumable: deploy a Rook on your half."
	rook.rarity = rarity.Tier.RARE; rook.base_cost = 5; rook.piece_code = 4
	pieces.append(rook)

	var chalice := TokenRes.new()
	chalice.type_name="Token"; chalice.id="token_chalice"; chalice.name="Golden Chalice"
	chalice.description="+1 gold at the start of each white turn."
	chalice.rarity = rarity.Tier.RARE; chalice.base_cost = 6
	chalice.passive_id = "START_TURN_GOLD"; chalice.passive_value = 1
	tokens.append(chalice)
	
func get_pool(kind: String) -> Array:
	match kind:
		"spell": return spells
		"piece": return pieces
		"token": return tokens
		_: return []
	
	print("ContentDB loaded:", spells.size(), "spells,", pieces.size(), "pieces,", tokens.size(), "tokens")
