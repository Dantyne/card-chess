extends Node
class_name TurnManager

signal turn_started(color: String)
signal turn_ended(color: String)

@export var base_move_cap: int = 3

var current_color: String = "white"
var white_moves_this_turn: int = 0
var extra_moves_bonus: int = 0

@onready var board: Node = $"../Board"              # or Board if you add class_name Board
@onready var ui: Node = $"../CanvasLayer"           # or UI if UI.gd uses class_name UI
@onready var shop: ShopManager = $"../ShopManager"  # optional; requires class_name ShopManager

func _ready() -> void:
	start_match()

func add_extra_moves_bonus(n: int) -> void:
	extra_moves_bonus += n
	ui.set_moves_left(moves_left())

func moves_cap() -> int:
	return base_move_cap + extra_moves_bonus

func moves_left() -> int:
	return max(0, moves_cap() - white_moves_this_turn)

func register_white_move() -> void:
	white_moves_this_turn += 1

func is_white_turn_over() -> bool:
	return white_moves_this_turn >= moves_cap()

func process_end_of_white_turn() -> void:
	emit_signal("turn_ended", "white")
	current_color = "black"
	board.white = false

	white_moves_this_turn = 0
	extra_moves_bonus = 0
	ui.set_moves_left(0)

	board.purge_white_on_black_back_row()
	board.replenish_black_back_row()
	board.display_board()
	await board.move_black_pieces_randomly()

	current_color = "white"
	board.white = true
	start_white_turn()

func start_match() -> void:
	current_color = "white"
	board.white = true
	white_moves_this_turn = 0
	extra_moves_bonus = 0
	start_white_turn()

func start_white_turn() -> void:
	# Board baseline (gold gain, draw, HUD it owns)
	board.start_white_turn()

	# Apply token passives (+gold, +moves, etc.)
	var token_mgr: TokenManager = $"../TokenManager"
	if is_instance_valid(token_mgr):
		token_mgr.apply_start_of_turn_passives(board.player, self)

	# Update HUD after passives
	if ui and ui.has_method("set_gold"):
		ui.set_gold(board.player.gold)
	ui.set_moves_left(moves_cap())

	emit_signal("turn_started", "white")

	# Auto-reroll shop
	var shop: ShopManager = $"../ShopManager"
	if is_instance_valid(shop):
		shop.on_turn_start_auto_reroll()
