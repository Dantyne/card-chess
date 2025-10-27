extends Resource
class_name ConsumableBase
@export var id: String
@export var name: String
@export var description: String
@export var rarity: int        # Rarity.Tier
@export var base_cost: int = 1
@export var icon: Texture2D
@export var tags: Array[String] = []
@export var type_name: String  # "Spell" | "Piece" | "Token"
