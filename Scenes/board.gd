extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 22

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const TURN_WHITE = preload("res://Assets/Your Turn.png")
const TURN_BLACK = preload("res://Assets/Enemy Turn.png")

const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")

const CARD_PAWN = preload("res://Assets/Card_Pawn.png")
const CARD_ROOK = preload("res://Assets/Card_Rook.png")
const CARD_KNIGHT = preload("res://Assets/Card_Knight.png")
const CARD_BISHOP = preload("res://Assets/Card_Bishop.png")
const CARD_QUEEN = preload("res://Assets/Card_Queen.png")
const CARD_SMITE = preload("res://Assets/Card_SMITE.png")
const CARD_EXTRA = preload("res://Assets/Card_Extra_Move.png")

const MANA = preload("res://Assets/MANA.png")
const HEALTH = preload("res://Assets/HEART.png")

const PIECE_MOVE = preload("res://Assets/piece_move.png")

const PIECE_SCORE := {
	1: 1,   # pawn
	2: 3,   # bishop
	3: 3,   # knight
	4: 5,   # rook
	5: 9,   # queen
	6: 0    # king (not really captured in your rules)
}

@onready var player = preload("res://Player.gd").new()
@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var cards_node = $Cards

#seperate .gd files
@onready var ui: Node = $"../CanvasLayer"   # CanvasLayer has UI.gd attached
@onready var input_ctrl = preload("res://InputController.gd").new()
@onready var rules: MoveRules = MoveRules.new()
@onready var turn_mgr: TurnManager = $"../TurnManager"

#Variables
# -6 = black king
# -5 = black queen
# -4 = black rook
# -3 = black knight
# -2 = black bishop
# -1 = black pawn
# 0 = empty
# 6 = white king
# 5 = white queen
# 4 = white rook
# 3 = white knight
# 2 = white bishop
# 1 = white pawn

var board : Array
var white : bool = true
var state : bool = false
var white_moves_this_turn : int = 0
var moves = []
var selected_piece : Vector2
var my_numbers = [0, -1, -2, -3, -4, -5]
var new_black_positions : Array = []

# --- Card system ---
enum CardType {
	SUMMON_PAWN, SUMMON_ROOK, SUMMON_KNIGHT, SUMMON_BISHOP, SUMMON_QUEEN,
	SMITE, EXTRA_MOVE
}

var deck: Array = []
var hand: Array = []
var discard: Array = []
var hand_nodes: Array[Node2D] = []

var hand_size := 3
var max_hand_size : int = 3

var card_targeting := false
var card_selected_idx := -1

# --- Scoring ---
var score: int = 0

# combo applies to WHITE captures within the same turn
var combo_count: int = 0              # 0 means no bonus yet
const COMBO_BASE: float = 1.0         # x1.0 for first capture
const COMBO_STEP: float = 0.5         # each consecutive capture adds +0.5 (x1.5, x2.0, x2.5, ...)

var extra_turns_pending: int = 0

var base_move_cap: int = 3        # normal moves per white turn
var extra_moves_bonus: int = 0    # +1 per Extra Move card this turn

var player_health: int = 10
var player_max_health: int = 10


func _ready() -> void:
	# --- 1. Initialize board layout ---
	board.append([4, 2, 3, 5, 6, 3, 2, 4])
	board.append([1, 1, 1, 1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([-4, -2, -3, -5, -6, -3, -2, -4])

	# --- 2. Add & configure helper scripts ---
	add_child(input_ctrl)
	input_ctrl.CELL_WIDTH = CELL_WIDTH
	input_ctrl.board_ref = self
	input_ctrl.piece_selected.connect(_on_piece_selected)
	input_ctrl.piece_deselected.connect(_on_piece_deselected)
	input_ctrl.move_attempted.connect(_on_move_attempted)
	add_child(rules)

	# --- 3. Connect Player and UI ---
	player.connect("gold_changed", func(g: int): ui.set_gold(g))

	# Optional: make sure HUD labels exist before updating
	if ui.has_method("update_hud_values"):
		ui.update_hud_values()

	# --- 4. Initialize Deck & Hand ---
	display_board()
	init_deck()
	render_hand()
	start_white_turn()
	display_board()

	# --- 5. Initialize Shop UI ---
	_wire_shop_ui()
	
func _wire_shop_ui() -> void:
	var shop: Node = get_node_or_null("../ShopManager")
	if shop and ui:
		if ui.has_method("ensure_shop"):
			ui.ensure_shop()
		if shop.has_method("roll_shop"):
			shop.roll_shop()

		if ui.has_method("show_shop"):
			ui.show_shop(shop.get("current"))
		if ui.has_method("bind_shop_controls"):
			ui.bind_shop_controls(shop)

		if shop.has_signal("shop_updated"):
			shop.shop_updated.connect(func(items):
				if ui.has_method("show_shop"):
					ui.show_shop(items)
				if ui.has_method("bind_shop_controls"):
					ui.bind_shop_controls(shop)
			)
		if shop.has_signal("purchase_failed"):
			shop.purchase_failed.connect(func(reason):
				if ui.has_method("show_shop_message"):
					ui.show_shop_message(reason)
			)
		if shop.has_signal("purchase_succeeded"):
			shop.purchase_succeeded.connect(func(item):
				if ui.has_method("show_shop_message"):
					ui.show_shop_message("Bought: " + item.name)
			)
	
func _input(event):
	if not (event is InputEventMouseButton and event.pressed):
		return
	var mx = get_global_mouse_position()

	# --- Right-click: cancel targeting or selection owned by Board (cards) ---
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if card_targeting:
			card_targeting = false
			card_selected_idx = -1
			delete_dots()
			return
		# if we didn't handle a card case, let InputController handle generic deselect
		if input_ctrl.process_board_click(event):
			return
		return

	# --- Left-click handling ---
	if event.button_index == MOUSE_BUTTON_LEFT:
		# 1) Cards take priority
		var idx := card_index_at_mouse(mx)
		if idx != -1:
			try_play_card(idx)
			return

		# 2) Card targeting to a board square
		if card_targeting:
			if is_mouse_out():
				return
			var var1 = int(snapped(mx.x, 0) / CELL_WIDTH)
			var var2 = int(abs(snapped(mx.y, 0)) / CELL_WIDTH)
			apply_card_to_square(var2, var1)
			return

		# 3) Otherwise, delegate board clicks to InputController
		if input_ctrl.process_board_click(event):
			return

func _on_piece_selected(pos: Vector2) -> void:
	# Only allow selecting your own piece
	if (white and board[int(pos.x)][int(pos.y)] > 0) or (!white and board[int(pos.x)][int(pos.y)] < 0):
		selected_piece = pos
		show_options()
		state = true
	else:
		_on_piece_deselected()

func _on_piece_deselected() -> void:
	state = false
	delete_dots()

func _on_move_attempted(from: Vector2, to: Vector2) -> void:
	# If clicking same piece, deselect
	if from == to:
		_on_piece_deselected()
		return
	# Let your existing move resolver run
	set_move(int(to.x), int(to.y))

func is_mouse_out() -> bool:
	return get_global_mouse_position().x < 0 \
		or get_global_mouse_position().x > 176 \
		or get_global_mouse_position().y > 0 \
		or get_global_mouse_position().y < -176
	
func display_board ():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.set_global_position(Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2 ), -i * CELL_WIDTH - (CELL_WIDTH / 2 )))
			
				
			match board[i][j]:
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_KNIGHT
				-2: holder.texture = BLACK_BISHOP
				-1: holder.texture = BLACK_PAWN
				0: holder.texture = null
				1: holder.texture = WHITE_PAWN
				2: holder.texture = WHITE_BISHOP
				3: holder.texture = WHITE_KNIGHT
				4: holder.texture = WHITE_ROOK
				5: holder.texture = WHITE_QUEEN
				6: holder.texture = WHITE_KING

	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK
	

func _score_value(piece_abs: int) -> int:
	return PIECE_SCORE.get(piece_abs, 0)

func _combo_multiplier() -> float:
	return COMBO_BASE + float(combo_count) * COMBO_STEP

func _award_white_capture(captured_abs: int) -> void:
	var base: int = _score_value(captured_abs)
	if base <= 0:
		return

	var points: int = int(round(float(base) * _combo_multiplier()))
	score += points
	combo_count += 1  # combo for scoring

	# --- Gold reward (new) ---
	var gold_gain: int = max(1, int(base / 2))  # adjust rate: half piece value minimum 1

	if player.has_method("gain_gold"):
		player.gain_gold(gold_gain)

	# HUD updates
	ui.set_gold(player.gold)
	ui.set_score(score, _combo_multiplier())

func _penalize_white_loss(lost_abs: int):
	var base := _score_value(lost_abs)
	if base <= 0:
		return
	score -= base

func _break_combo_if_any():
	if combo_count > 0:
		combo_count = 0


func show_options() -> void:
	var pval: int = abs(int(board[int(selected_piece.x)][int(selected_piece.y)]))
	var mv: Array[Vector2] = rules.raw_moves(pval, selected_piece, white, board)
	moves = mv  # keep using your existing 'moves' array
	if moves.is_empty():
		state = false
		return
	show_dots()
	
func show_dots():
	for i in moves:
		if typeof(i) != TYPE_VECTOR2:
			continue
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(
			int(i.y) * CELL_WIDTH + (CELL_WIDTH / 2),
			-int(i.x) * CELL_WIDTH - (CELL_WIDTH / 2)
		)
	
func delete_dots():
	for child in dots.get_children():
		child.queue_free()
	
func set_move(var2, var1):
	for i in moves:
		if typeof(i) != TYPE_VECTOR2:
			continue
		if int(i.x) == int(var2) and int(i.y) == int(var1):
			# safe, in-bounds write
			var from_x := int(selected_piece.x)
			var from_y := int(selected_piece.y)
			var to_x := int(var2)
			var to_y := int(var1)
			if to_x < 0 or to_x >= board.size(): return
			if to_y < 0 or to_y >= board[to_x].size(): return

			var captured_abs := 0
			if white and int(board[to_x][to_y]) < 0:
				captured_abs = abs(int(board[to_x][to_y]))

			board[to_x][to_y] = board[from_x][from_y]
			board[from_x][from_y] = 0

			display_board()
			delete_dots()
			state = false

			if white:
				if captured_abs > 0: _award_white_capture(captured_abs) 
				else: _break_combo_if_any()
				turn_mgr.register_white_move()
				ui.set_moves_left(turn_mgr.moves_left())
				if turn_mgr.is_white_turn_over():
					await turn_mgr.process_end_of_white_turn()
			return
		
func replenish_black_back_row():
	new_black_positions.clear()  # reset from last turn
	for col in range(BOARD_SIZE):
		if board[7][col] == 0:
			var new_piece = my_numbers.pick_random()
			board[7][col] = new_piece
			if new_piece != 0:
				new_black_positions.append(Vector2(7, col))
		
func move_black_pieces_randomly() -> void:
	var black_positions: Array[Vector2] = []

	# Collect all black pieces
	for x in range(board.size()):
		for y in range(board[x].size()):
			if int(board[x][y]) < 0:
				black_positions.append(Vector2(x, y))

	black_positions.shuffle()

	for pos in black_positions:
		# Skip new pieces spawned this turn
		if new_black_positions.has(pos):
			continue

		var piece_val: int = abs(int(board[int(pos.x)][int(pos.y)]))
		var moves: Array[Vector2] = rules.raw_moves(piece_val, pos, false, board)
		if moves.is_empty():
			continue

		# For black, "forward" means decreasing x (toward White’s side)
		var forward_moves: Array[Vector2] = []
		for m in moves:
			if m.x < pos.x:
				forward_moves.append(m)

		var valid_moves: Array[Vector2] = forward_moves
		if valid_moves.is_empty():
			valid_moves = moves

		var move: Vector2 = valid_moves.pick_random()

		var from_x: int = int(pos.x)
		var from_y: int = int(pos.y)
		var to_x: int = int(move.x)
		var to_y: int = int(move.y)

		# Penalize when BLACK captures a WHITE piece
		if int(board[to_x][to_y]) > 0:
			_penalize_white_loss(abs(int(board[to_x][to_y])))
			ui.set_score(score, _combo_multiplier())

		# Execute the move
		board[to_x][to_y] = board[from_x][from_y]
		board[from_x][from_y] = 0

		display_board()

		# Delay between each black move
		await get_tree().create_timer(0.5).timeout

	# After all black moves, check if any black piece reached White’s final row
	check_black_pieces_on_final_row()
	ui.set_health(player_health, player_max_health)

func purge_white_on_black_back_row():
	var removed := false
	for y in range(BOARD_SIZE):
		if board[7][y] > 0:
			_penalize_white_loss(abs(board[7][y]))
			ui.set_score(score, _combo_multiplier())
			board[7][y] = 0
			removed = true
	if removed:
		display_board()
	
func check_black_pieces_on_final_row():
	for y in range(BOARD_SIZE):
		if board[0][y] < 0:
			# Black piece reached the bottom (player side)
			board[0][y] = 0  # remove it
			player_health -= 1
			print("⚔️ Player took 1 damage! Health =", player_health, "/", player_max_health)

			# Optional: if you want a loss condition
			if player_health <= 0:
				game_over()
	
func game_over():
	print("💀 Game Over! Player defeated.")
	# You could later add a UI overlay, stop inputs, etc.
	get_tree().paused = true
	
func is_black_piece(value):
	# Adjust depending on how you represent pieces
	# Example: white pieces > 0, black pieces < 0
	return value < 0
	
func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false
	
func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false

func is_enemy(pos : Vector2):
	if white && board[pos.x][pos.y] < 0 || !white && board[pos.x][pos.y] > 0: return true
	return false


func make_card(t: int) -> Dictionary:
	match t:
		CardType.SUMMON_PAWN:
			return {"type": t, "name": "Summon Pawn",   "cost": 1, "texture": CARD_PAWN,   "desc": "Place a white pawn on your half."}
		CardType.SUMMON_ROOK:
			return {"type": t, "name": "Summon Rook",   "cost": 2, "texture": CARD_ROOK,   "desc": "Place a white rook on your half."}
		CardType.SUMMON_KNIGHT:
			return {"type": t, "name": "Summon Knight", "cost": 2, "texture": CARD_KNIGHT, "desc": "Place a white knight on your half."}
		CardType.SUMMON_BISHOP:
			return {"type": t, "name": "Summon Bishop", "cost": 2, "texture": CARD_BISHOP, "desc": "Place a white bishop on your half."}
		CardType.SUMMON_QUEEN:
			return {"type": t, "name": "Summon Queen",  "cost": 3, "texture": CARD_QUEEN,  "desc": "Place a white queen on your half."}
		CardType.SMITE:
			return {"type": t, "name": "Smite",         "cost": 2, "texture": CARD_SMITE, "desc": "Destroy a black piece."}
		CardType.EXTRA_MOVE:
			return {"type": t, "name": "Extra Move",    "cost": 1, "texture": CARD_EXTRA, "desc": "Gain +1 move this turn."}
	return {}

func init_deck():
	deck.clear()
	# Simple starter deck — adjust counts to taste
	for i in 5: deck.append(make_card(CardType.SUMMON_PAWN))
	for i in 2: deck.append(make_card(CardType.SUMMON_ROOK))
	for i in 3: deck.append(make_card(CardType.SUMMON_KNIGHT))
	for i in 3: deck.append(make_card(CardType.SUMMON_BISHOP))
	for i in 1: deck.append(make_card(CardType.SUMMON_QUEEN))
	for i in 3: deck.append(make_card(CardType.SMITE))
	for i in 4: deck.append(make_card(CardType.EXTRA_MOVE))
	deck.shuffle()

func start_white_turn() -> void:
	# Base economy & per-turn reset that Board owns
	player.gain_gold(1)
	combo_count = 0

	# Draw & layout
	draw_cards_to(hand_size)
	render_hand()
	ui.layout_beside_cards(hand_nodes)

	# HUD owned by Board values
	ui.set_gold(player.gold)
	ui.set_score(score, _combo_multiplier())
	ui.set_health(player_health, player_max_health)


func draw_cards_to(size: int) -> void:
	while hand.size() < size and deck.size() > 0:
		hand.append(deck.pop_back())
	# No UI calls here; render/layout handled by caller.

func discard_card(idx: int):
	if idx < 0 or idx >= hand.size(): return
	discard.append(hand[idx])
	hand.remove_at(idx)
	render_hand()

func render_hand():
	# clear old UI
	for n in hand_nodes:
		n.queue_free()
	hand_nodes.clear()

	# --- Board geometry ---
	var board_px: float = float(BOARD_SIZE * CELL_WIDTH)
	var board_left: float = CELL_WIDTH * 0.5
	var board_right: float = board_px - CELL_WIDTH * 0.5
	var board_center_x: float = (board_left + board_right) * 0.5

	# --- Hand layout ---
	var spacing: float = CELL_WIDTH * 1.3                  # distance between card centers
	var total_w: float = float(max(1, hand.size())) * spacing
	var start_x: float = board_center_x - ((hand.size() - 1) * spacing) * 0.5

	# Put the hand just **below the board** (White’s side)
	var cards_y: float = CELL_WIDTH * 1.5                   # tweak 1.0..2.5 to move

	for i in range(hand.size()):
		var holder = TEXTURE_HOLDER.instantiate()
		cards_node.add_child(holder)
		holder.texture = hand[i]["texture"]
		holder.global_position = Vector2(start_x + i * spacing, cards_y)
		holder.name = "Card_%d" % i
		hand_nodes.append(holder as Node2D)
		
		
func card_index_at_mouse(pos: Vector2) -> int:
	# very simple hit test: distance to sprite center < CELL_WIDTH
	for i in range(hand_nodes.size()):
		var n: Node2D = hand_nodes[i]
		if pos.distance_to(n.global_position) <= CELL_WIDTH * 0.7:
			return i
	return -1

func try_play_card(idx: int):
	if idx < 0 or idx >= hand.size(): 
		return

	var c: Dictionary = hand[idx]
	var t := int(c["type"])
	if player.gold < int(c["cost"]):
		return

	match t:
		CardType.EXTRA_MOVE:
			# +1 move this white turn
			turn_mgr.add_extra_moves_bonus(1)
			player.spend_gold(int(c["cost"]))
			discard_card(idx)
			render_hand()
			ui.set_gold(player.gold)
			ui.set_moves_left(turn_mgr.moves_left())

		_:  # SUMMON_* or SMITE needs a target
			card_selected_idx = idx
			card_targeting = true
			show_card_targets(c)

func show_card_targets(c: Dictionary):
	delete_dots()
	var t := int(c["type"])
	var targets: Array = []

	if t == CardType.SMITE:
		# any black piece
		for x in range(BOARD_SIZE):
			for y in range(BOARD_SIZE):
				if board[x][y] < 0:
					targets.append(Vector2(x, y))
	else:
		# Any SUMMON_* card: empty squares on White half (rows 0..3)
		for x in range(0, 4):
			for y in range(BOARD_SIZE):
				if board[x][y] == 0:
					targets.append(Vector2(x, y))

	# show targets as dots
	for tgt in targets:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(tgt.y * CELL_WIDTH + (CELL_WIDTH / 2), -tgt.x * CELL_WIDTH - (CELL_WIDTH / 2))

func _piece_value_for_summon(t: int) -> int:
	match t:
		CardType.SUMMON_PAWN:   return 1
		CardType.SUMMON_ROOK:   return 4
		CardType.SUMMON_KNIGHT: return 3
		CardType.SUMMON_BISHOP: return 2
		CardType.SUMMON_QUEEN:  return 5
	return 0

func apply_card_to_square(var2: int, var1: int):
	if card_selected_idx == -1 or card_selected_idx >= hand.size(): return
	var c: Dictionary = hand[card_selected_idx]
	var t := int(c["type"])
	var cost := int(c["cost"])

	# Summons
	if t == CardType.SUMMON_PAWN or t == CardType.SUMMON_ROOK or t == CardType.SUMMON_KNIGHT or t == CardType.SUMMON_BISHOP or t == CardType.SUMMON_QUEEN:
		# must be empty and on White half
		if board[var2][var1] == 0 and var2 <= 3:
			board[var2][var1] = _piece_value_for_summon(t)
			player.spend_gold(int(c["cost"]))
			ui.set_gold(player.gold)
			discard_card(card_selected_idx)
	# Smite
	elif t == CardType.SMITE:
		if board[var2][var1] < 0:
			board[var2][var1] = 0
			player.spend_gold(int(c["cost"]))
			ui.set_gold(player.gold)
			discard_card(card_selected_idx)

	card_selected_idx = -1
	card_targeting = false
	delete_dots()
	display_board()
	
