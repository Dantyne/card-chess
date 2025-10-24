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

@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var cards_node = $Cards
@onready var hud_panel: Panel = null
@onready var ui_layer: CanvasLayer = null
@onready var hud_group: Control = null
@onready var health_icon: TextureRect = null
@onready var health_label: Label = null
@onready var mana_icon: TextureRect = null
@onready var mana_label: Label = null
@onready var moves_label: Label = null
@onready var score_label: Label = null
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

var mana_max := 5
var mana := 5
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


func _ready():
	
	board.append([4, 2, 3, 5, 6, 3, 2, 4])
	board.append([1, 1, 1, 1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([my_numbers.pick_random(), my_numbers.pick_random(), my_numbers.pick_random(), my_numbers.pick_random(), my_numbers.pick_random(), my_numbers.pick_random(), my_numbers.pick_random(), my_numbers.pick_random()])
	
	display_board()          # Draw the board first
	init_deck()              # Build your card deck

	ensure_hud()             # Create HUD and icons
	render_hand()            # Show player’s starting hand
	update_hud_layout()      # Position icons beside cards
	update_hud_values()      # Display correct HP / Mana values

	start_white_turn()       # Give White a hand at start
	display_board()          # Final refresh
	
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mx = get_global_mouse_position()

		# --- Right-click: cancel targeting or selection ---
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if card_targeting:
				card_targeting = false
				card_selected_idx = -1
				delete_dots()
			elif state:
				state = false
				delete_dots()
			return

		# --- Left-click handling ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 1) Cards take priority: click on a card to play/enter targeting
			var idx := card_index_at_mouse(mx)
			if idx != -1:
				try_play_card(idx)
				return

			# 2) If we are targeting a card effect, apply it to a board square
			if card_targeting:
				if is_mouse_out():
					return  # click outside board while targeting = ignore (right-click cancels)
				var var1 = int(snapped(mx.x, 0) / CELL_WIDTH)
				var var2 = int(abs(snapped(mx.y, 0)) / CELL_WIDTH)
				apply_card_to_square(var2, var1)
				return

			# 3) Normal board interaction
			# Clicked off the board? Deselect current piece selection.
			if is_mouse_out():
				if state:
					state = false
					delete_dots()
				return

			var var1 = int(snapped(mx.x, 0) / CELL_WIDTH)
			var var2 = int(abs(snapped(mx.y, 0)) / CELL_WIDTH)
			var clicked := Vector2(var2, var1)

			if !state:
				# Select a piece if it’s your color
				if (white and board[var2][var1] > 0) or (!white and board[var2][var1] < 0):
					selected_piece = clicked
					show_options()
					state = true
				return
			else:
				# If clicking the same piece, toggle off (deselect)
				if clicked == selected_piece:
					state = false
					delete_dots()
					return

				# If clicking another of your pieces, switch selection
				if (white and board[var2][var1] > 0) or (!white and board[var2][var1] < 0):
					delete_dots()
					selected_piece = clicked
					show_options()
					return

				# Otherwise try to move to that square
				set_move(var2, var1)
				
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
	
func ensure_ui_layer():
	if has_node("UILayer"):
		ui_layer = get_node("UILayer") as CanvasLayer
	else:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UILayer"
		add_child(ui_layer)
	
func ensure_hud():
	ensure_ui_layer()

	if ui_layer.has_node("HUDGroup"):
		hud_group   = ui_layer.get_node("HUDGroup") as Control
		health_icon = hud_group.get_node("HealthIcon") as TextureRect
		health_label= hud_group.get_node("HealthLabel") as Label
		mana_icon   = hud_group.get_node("ManaIcon") as TextureRect
		mana_label  = hud_group.get_node("ManaLabel") as Label
		moves_label = hud_group.get_node("MovesLabel") as Label
		score_label = hud_group.get_node("ScoreLabel") as Label
		return

	hud_group = Control.new()
	hud_group.name = "HUDGroup"
	hud_group.z_index = 1000
	hud_group.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ui_layer.add_child(hud_group)

	# HEALTH
	health_icon = TextureRect.new()
	health_icon.name = "HealthIcon"
	health_icon.texture = HEALTH
	health_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	health_icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_group.add_child(health_icon)

	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "HP: %d/%d" % [player_health, player_max_health]
	health_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(1,1,1))
	health_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	health_label.add_theme_constant_override("outline_size", 2)
	hud_group.add_child(health_label)

	# MANA
	mana_icon = TextureRect.new()
	mana_icon.name = "ManaIcon"
	mana_icon.texture = MANA
	mana_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	mana_icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_group.add_child(mana_icon)

	mana_label = Label.new()
	mana_label.name = "ManaLabel"
	mana_label.text = "Mana: %d/%d" % [mana, mana_max]
	mana_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mana_label.add_theme_font_size_override("font_size", 16)
	mana_label.add_theme_color_override("font_color", Color(1,1,1))
	mana_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	mana_label.add_theme_constant_override("outline_size", 2)
	hud_group.add_child(mana_label)

		# --- MOVES (text only; add an icon if you want) ---
	moves_label = Label.new()
	moves_label.name = "MovesLabel"
	moves_label.text = "Moves: 0/0"
	moves_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	moves_label.add_theme_font_size_override("font_size", 16)
	moves_label.add_theme_color_override("font_color", Color(1,1,1))
	moves_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	moves_label.add_theme_constant_override("outline_size", 2)
	hud_group.add_child(moves_label)

	# If you want an icon above the label, uncomment this block:
	# moves_icon = TextureRect.new()
	# moves_icon.name = "MovesIcon"
	# moves_icon.texture = MOVES_ICON
	# moves_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	# moves_icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# hud_group.add_child(moves_icon)

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.add_theme_color_override("font_color", Color(1,1,1))
	score_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	score_label.add_theme_constant_override("outline_size", 2)
	hud_group.add_child(score_label)

func update_hud_layout():
	if hud_group == null:
		return

	# If we have any card nodes, anchor to the last one’s screen position
	var base_pos: Vector2
	if hand_nodes.size() > 0:
		var last_card: Node2D = hand_nodes.back()
		base_pos = last_card.global_position
	else:
		# Fallback: approximate the card row center
		var board_px: float = float(BOARD_SIZE * CELL_WIDTH)
		var board_left: float = CELL_WIDTH * 0.5
		var board_right: float = board_px - CELL_WIDTH * 0.5
		var board_center_x: float = (board_left + board_right) * 0.5
		var spacing: float = CELL_WIDTH * 1.3
		var cards_y: float = CELL_WIDTH * 1.5
		var start_x: float = board_center_x - ((max(1, hand.size()) - 1) * spacing) * 0.5
		base_pos = Vector2(start_x + max(0, hand.size() - 1) * spacing, cards_y)

	# Push the HUD a good distance to the right of the last card
	var hud_x: float = base_pos.x + CELL_WIDTH * 4.0
	var hud_y: float = base_pos.y  # align vertically with card row

	# Sizing & gaps
	var icon_h: float = float(CELL_WIDTH)
	var label_h: float = 16.0               # approx label height (matches your font size)
	var v_gap: float = CELL_WIDTH * 5.25    # gap between icon and its label
	var group_gap: float = CELL_WIDTH * 5.40  # extra gap between blocks

	# Optional: scale icons slightly so labels have room
	health_icon.scale = Vector2(0.9, 0.9)
	mana_icon.scale   = Vector2(0.9, 0.9)

	# --- HEALTH block ---
	health_icon.position  = Vector2(hud_x, hud_y)
	var health_label_y    = hud_y + icon_h + v_gap
	health_label.position = Vector2(hud_x + CELL_WIDTH * 0.5, health_label_y)
	health_label.z_index  = 5

	# --- MANA block (stacked below HEALTH block) ---
	var mana_y            = health_label_y + label_h + group_gap
	mana_icon.position    = Vector2(hud_x, mana_y)
	var mana_label_y      = mana_y + icon_h + v_gap
	mana_label.position   = Vector2(hud_x + CELL_WIDTH * 0.5, mana_label_y)
	mana_label.z_index    = 5
	
	# --- MOVES (text only; stacked below MANA block) ---
	var moves_y: float = mana_label_y + label_h + group_gap
	moves_label.position = Vector2(hud_x + CELL_WIDTH * 0.5, moves_y)
	moves_label.z_index = 5

	# --- SCORE (stacked below MOVES) ---
	var score_y: float = moves_y + label_h + group_gap
	score_label.position = Vector2(hud_x + CELL_WIDTH * 0.5, score_y)
	score_label.z_index = 5

func update_hud():
	if health_label:
		health_label.text = "HP: %d/%d" % [player_health, player_max_health]
	if mana_label:
		mana_label.text = "Mana: %d/%d" % [mana, mana_max]
		
func update_hud_values():
	if health_label:
		health_label.text = "HP: %d/%d" % [player_health, player_max_health]

	if mana_label:
		mana_label.text = "Mana: %d/%d" % [mana, mana_max]

	if moves_label:
		var cap := base_move_cap + extra_moves_bonus
		var remaining: int = max(0, cap - white_moves_this_turn)
		moves_label.text = "Moves Left: %d" % remaining

	if score_label:
		var combo_txt := ""
		if combo_count > 0:
			combo_txt = "  (x%.1f)" % _combo_multiplier()
		score_label.text = "Score: %d%s" % [score, combo_txt]

func _score_value(piece_abs: int) -> int:
	return PIECE_SCORE.get(piece_abs, 0)

func _combo_multiplier() -> float:
	return COMBO_BASE + float(combo_count) * COMBO_STEP

func _award_white_capture(captured_abs: int):
	var base := _score_value(captured_abs)
	if base <= 0: 
		return
	var points := int(round(float(base) * _combo_multiplier()))
	score += points
	combo_count += 1  # consecutive capture improves multiplier for next one
	update_hud_values()

func _penalize_white_loss(lost_abs: int):
	var base := _score_value(lost_abs)
	if base <= 0:
		return
	score -= base
	update_hud_values()

func _break_combo_if_any():
	if combo_count > 0:
		combo_count = 0
		update_hud_values()


func show_options():
	moves = get_moves()
	if moves == []:
		state = false
		return
	show_dots()
	
func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH / 2), -i.x * CELL_WIDTH - (CELL_WIDTH / 2))
	
func delete_dots():
	for child in dots.get_children():
		child.queue_free()
	
func set_move(var2, var1):
	for i in moves:
		if i.x == var2 and i.y == var1:
			# Was this a capture?
			var captured_abs := 0
			if white and board[var2][var1] < 0:
				captured_abs = abs(board[var2][var1])

			# Move the selected piece
			board[var2][var1] = board[selected_piece.x][selected_piece.y]
			board[selected_piece.x][selected_piece.y] = 0

			display_board()
			delete_dots()
			state = false

			if white:
				# Update score / combo
				if captured_abs > 0:
					_award_white_capture(captured_abs)
				else:
					_break_combo_if_any()

				white_moves_this_turn += 1
				update_hud_values()

				# End White's turn if move limit reached (3 + any bonuses)
				if white_moves_this_turn >= (base_move_cap + extra_moves_bonus):
					white = false
					white_moves_this_turn = 0
					extra_moves_bonus = 0  # reset bonus for next turn
					update_hud_values()

					# Remove white pieces on Black's back row (and penalize loss)
					purge_white_on_black_back_row()

					replenish_black_back_row()
					display_board()
					move_black_pieces_randomly()

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
	var black_positions = []

	# Collect all black pieces
	for x in range(board.size()):
		for y in range(board[x].size()):
			if board[x][y] < 0:
				black_positions.append(Vector2(x, y))

	black_positions.shuffle()

	for pos in black_positions:
		# Skip new pieces spawned this turn
		if new_black_positions.has(pos):
			continue

		var moves = get_moves_for_piece(pos, false)
		if moves.size() == 0:
			continue

		# For black, "forward" means decreasing x (toward White’s side)
		var forward_moves: Array = []
		for m in moves:
			if m.x < pos.x:
				forward_moves.append(m)

		var valid_moves = forward_moves if forward_moves.size() > 0 else moves
		var move = valid_moves.pick_random()

		var from_x := int(pos.x)
		var from_y := int(pos.y)
		var to_x := int(move.x)
		var to_y := int(move.y)

		# --- Step 4: Penalize when BLACK captures a WHITE piece ---
		if board[to_x][to_y] > 0:
			_penalize_white_loss(abs(board[to_x][to_y]))  # updates score/HUD

		# Execute the move
		board[to_x][to_y] = board[from_x][from_y]
		board[from_x][from_y] = 0

		display_board()

		# Delay between each black move
		await get_tree().create_timer(0.5).timeout

	# After all black moves, check if any black piece reached White’s final row
	check_black_pieces_on_final_row()

	# Switch back to White’s turn
	white = true
	start_white_turn()
	display_board()
	
func purge_white_on_black_back_row():
	var removed := false
	for y in range(BOARD_SIZE):
		if board[7][y] > 0:
			_penalize_white_loss(abs(board[7][y]))
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
			update_hud()
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
	
func get_moves():
		var _moves = []
		match abs(board[selected_piece.x][selected_piece.y]):
			1: _moves = get_pawn_moves()
			2: _moves = get_bishop_moves()
			3: _moves = get_knight_moves()
			4: _moves = get_rook_moves()
			5: _moves = get_queen_moves()
			6: _moves = get_king_moves()

		return _moves
		
func get_moves_for_piece(pos: Vector2, is_white: bool) -> Array:
	var _moves = []
	var piece = abs(board[pos.x][pos.y])

	# Temporarily store current context
	var prev_selected = selected_piece
	var prev_white = white

	selected_piece = pos
	white = is_white

	match piece:
		1: _moves = get_pawn_moves()
		2: _moves = get_bishop_moves()
		3: _moves = get_knight_moves()
		4: _moves = get_rook_moves()
		5: _moves = get_queen_moves()
		6: _moves = get_king_moves()

	# Restore context
	selected_piece = prev_selected
	white = prev_white

	return _moves
		
func get_king_moves():
	var _moves = []
	var directions = [Vector2(1,1), Vector2 (1, -1), Vector2 (-1, -1), Vector2 (-1, 1), Vector2(0, 1), Vector2 (0, -1), Vector2 (1, 0), Vector2 (-1, 0)]
	
	for i in directions:
		var pos = selected_piece + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
		
	return _moves

func get_pawn_moves() -> Array:
	var _moves = []
	var direction = Vector2(1, 0) if white else Vector2(-1, 0)

	# One step forward
	var pos = selected_piece + direction
	if is_valid_position(pos) and is_empty(pos):
		_moves.append(pos)

		# Two steps forward (only if first move)
		var start_row = 1 if white else 6  # white pawns start at row 1, black at row 6
		if int(selected_piece.x) == start_row:
			var two_step = selected_piece + direction * 2
			if is_valid_position(two_step) and is_empty(two_step):
				_moves.append(two_step)

	# Diagonal attacks
	for dy in [-1, 1]:
		pos = selected_piece + Vector2(direction.x, dy)
		if is_valid_position(pos) and is_enemy(pos):
			_moves.append(pos)

	return _moves

func get_knight_moves():
	var _moves = []
	var directions = []

	if white:
		# White: all 8 L moves
		directions = [
			Vector2(2, 1), Vector2(2, -1),
			Vector2(-2, 1), Vector2(-2, -1),
			Vector2(1, 2), Vector2(1, -2),
			Vector2(-1, 2), Vector2(-1, -2)
		]
	else:
		# Black: only L moves that go forward (x decreases)
		directions = [
			Vector2(-2, 1), Vector2(-2, -1),
			Vector2(-1, 2), Vector2(-1, -2)
		]

	for dir in directions:
		var pos = selected_piece + dir
		if is_valid_position(pos) and (is_empty(pos) or is_enemy(pos)):
			_moves.append(pos)
	return _moves

func get_rook_moves():
	var _moves = []

	var dirs = []
	if white:
		dirs = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
	else:
		# Black: forward (x - 1) and sideways only
		dirs = [Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]

	for dir in dirs:
		var pos = selected_piece
		for step in range(2):  # keep your 2-tile cap
			pos += dir
			if !is_valid_position(pos): break
			if is_empty(pos):
				_moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos); break
			else:
				break
	return _moves

func get_bishop_moves():
	var _moves = []

	var dirs = []
	if white:
		dirs = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	else:
		# Black: forward diagonals only (x decreases)
		dirs = [Vector2(-1,1), Vector2(-1,-1)]

	for dir in dirs:
		var pos = selected_piece
		for step in range(2):
			pos += dir
			if !is_valid_position(pos): break
			if is_empty(pos):
				_moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos); break
			else:
				break
	return _moves

func get_queen_moves():
	var _moves = []

	var dirs = []
	if white:
		dirs = [
			Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1),
			Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
		]
	else:
		# Black: forward (x - 1), sideways, forward diagonals
		dirs = [
			Vector2(-1,0), Vector2(0,1), Vector2(0,-1),
			Vector2(-1,1), Vector2(-1,-1)
		]

	for dir in dirs:
		var pos = selected_piece
		for step in range(3):  # keep your 3-tile cap
			pos += dir
			if !is_valid_position(pos): break
			if is_empty(pos):
				_moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos); break
			else:
				break
	return _moves

	
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

func start_white_turn():
	mana = mana_max
	extra_moves_bonus = 0    # reset extra moves gained last turn
	combo_count = 0                 # reset combo each new white turn
	update_hud_values()        
	draw_cards_to(hand_size)
	render_hand()

func draw_cards_to(size: int):
	while hand.size() < size and deck.size() > 0:
		hand.append(deck.pop_back())
	render_hand()
	update_hud()

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
		
	update_hud_layout()
		
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
	if mana < int(c["cost"]): 
		return

	match t:
		CardType.EXTRA_MOVE:
			# +1 move for the CURRENT white turn (stackable)
			extra_moves_bonus += 1
			mana -= int(c["cost"])
			discard_card(idx)
			update_hud_values()
			render_hand()
			update_hud()

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
			mana -= cost
			discard_card(card_selected_idx)
			update_hud_values()
	# Smite
	elif t == CardType.SMITE:
		if board[var2][var1] < 0:
			board[var2][var1] = 0
			mana -= cost
			discard_card(card_selected_idx)
			update_hud_values()

	card_selected_idx = -1
	card_targeting = false
	delete_dots()
	display_board()
	
