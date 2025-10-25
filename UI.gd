# UI.gd
extends CanvasLayer

# references created at runtime
var hud_group: Control
var health_icon: TextureRect
var health_label: Label
var gold_icon: TextureRect
var gold_label: Label
var moves_label: Label
var score_label: Label

# reuse your existing textures
const HEALTH = preload("res://Assets/HEART.png")
const MANA  = preload("res://Assets/MANA.png") # temporary; swap to a Gold icon later
const CELL_WIDTH := 22
const BOARD_SIZE := 8

func _ready() -> void:
	_build_hud()

func _build_hud() -> void:
	# group root
	hud_group = Control.new()
	hud_group.name = "HUDGroup"
	hud_group.z_index = 1000
	hud_group.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(hud_group)

	# HEALTH
	health_icon = TextureRect.new()
	health_icon.name = "HealthIcon"
	health_icon.texture = HEALTH
	health_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hud_group.add_child(health_icon)

	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(1,1,1))
	health_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	health_label.add_theme_constant_override("outline_size", 2)
	hud_group.add_child(health_label)

	# GOLD (reuse mana icon for now)
	gold_icon = TextureRect.new()
	gold_icon.name = "GoldIcon"
	gold_icon.texture = MANA
	gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hud_group.add_child(gold_icon)

	gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.add_theme_font_size_override("font_size", 16)
	gold_label.add_theme_color_override("font_color", Color(1,1,1))
	gold_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	gold_label.add_theme_constant_override("outline_size", 2)
	hud_group.add_child(gold_label)

	# MOVES
	moves_label = Label.new()
	moves_label.name = "MovesLabel"
	moves_label.add_theme_font_size_override("font_size", 16)
	moves_label.add_theme_color_override("font_color", Color(1,1,1))
	moves_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	moves_label.add_theme_constant_override("outline_size", 2)
	hud_group.add_child(moves_label)

	# SCORE
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.add_theme_color_override("font_color", Color(1,1,1))
	score_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	score_label.add_theme_constant_override("outline_size", 2)
	hud_group.add_child(score_label)

# ---------- Layout & update API (call these from Board) ----------

func layout_beside_cards(hand_nodes: Array) -> void:
	# compute anchor using last card position or a fallback
	var base_pos: Vector2
	if hand_nodes.size() > 0:
		var last_card: Node2D = hand_nodes.back()
		base_pos = last_card.global_position
	else:
		var board_px: float = float(BOARD_SIZE * CELL_WIDTH)
		var board_left: float = CELL_WIDTH * 0.5
		var board_right: float = board_px - CELL_WIDTH * 0.5
		var board_center_x: float = (board_left + board_right) * 0.5
		var spacing: float = CELL_WIDTH * 1.3
		var cards_y: float = CELL_WIDTH * 1.5
		var start_x: float = board_center_x - ((max(1, hand_nodes.size()) - 1) * spacing) * 0.5
		base_pos = Vector2(start_x + max(0, hand_nodes.size() - 1) * spacing, cards_y)

	var hud_x: float = base_pos.x + CELL_WIDTH * 4.0
	var hud_y: float = base_pos.y

	var icon_h: float = float(CELL_WIDTH)
	var label_h: float = 16.0
	var v_gap: float = CELL_WIDTH * 5.25
	var group_gap: float = CELL_WIDTH * 5.40

	health_icon.scale = Vector2(0.9, 0.9)
	gold_icon.scale   = Vector2(0.9, 0.9)

	health_icon.position = Vector2(hud_x, hud_y)
	var health_label_y = hud_y + icon_h + v_gap
	health_label.position = Vector2(hud_x + CELL_WIDTH * 0.5, health_label_y)
	health_label.z_index = 5

	var gold_y = health_label_y + label_h + group_gap
	gold_icon.position = Vector2(hud_x, gold_y)
	var gold_label_y = gold_y + icon_h + v_gap
	gold_label.position = Vector2(hud_x + CELL_WIDTH * 0.5, gold_label_y)
	gold_label.z_index = 5

	var moves_y = gold_label_y + label_h + group_gap
	moves_label.position = Vector2(hud_x + CELL_WIDTH * 0.5, moves_y)
	moves_label.z_index = 5

	var score_y = moves_y + label_h + group_gap
	score_label.position = Vector2(hud_x + CELL_WIDTH * 0.5, score_y)
	score_label.z_index = 5

func set_health(current:int, maxv:int) -> void:
	if health_label:
		health_label.text = "HP: %d/%d" % [current, maxv]

func set_gold(gold:int) -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % gold

func set_moves_left(remaining:int) -> void:
	if moves_label:
		moves_label.text = "Moves Left: %d" % remaining

func set_score(score: int, combo_mult: float) -> void:
	if score_label:
		var combo_txt := "  (x%.1f)" % combo_mult if combo_mult > 1.0 else ""
		score_label.text = "Score: %d%s" % [score, combo_txt]
