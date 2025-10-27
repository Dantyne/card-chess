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
var inv_label: Label

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
		
# --- SHOP UI minimal ---
# --- SHOP UI REFS ---
@onready var shop_panel = $HUDGroup/ShopPanel
@onready var shop_status: Label = $HUDGroup/ShopPanel/VBoxContainer/ShopStatus
@onready var reroll_btn: Button = $HUDGroup/ShopPanel/VBoxContainer/RerollButton
@onready var shop_items: VBoxContainer = $HUDGroup/ShopPanel/VBoxContainer/ShopItems
var shop_buttons: Array[Button] = []

func ensure_shop() -> void:
	if shop_panel: return
	shop_panel = Panel.new()
	shop_panel.name = "ShopPanel"
	add_child(shop_panel)
	shop_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	shop_panel.size = Vector2(300, 260)
	shop_panel.position = Vector2(-310, 10) # 10px from top-right

	var title := Label.new()
	title.text = "Shop"
	title.add_theme_font_size_override("font_size", 16)
	title.position = Vector2(10, 8)
	shop_panel.add_child(title)

	reroll_btn = Button.new()
	reroll_btn.text = "Reroll"
	reroll_btn.position = Vector2(220, 6)
	shop_panel.add_child(reroll_btn)

	shop_status = Label.new()
	shop_status.position = Vector2(10, 230)
	shop_status.size = Vector2(280, 22)
	shop_panel.add_child(shop_status)

	inv_label = Label.new()
	inv_label.position = Vector2(10, 210)
	inv_label.text = ""
	shop_panel.add_child(inv_label)

func show_shop(items: Array) -> void:
	ensure_shop()

	# clear old
	for b in shop_buttons:
		b.queue_free()
	shop_buttons.clear()

	var y := 36
	for i in range(items.size()):
		var c = items[i]
		var btn := Button.new()
		btn.position = Vector2(10, y)
		btn.size = Vector2(280, 30)
		btn.name = "ShopBuy_%d" % i

		if c == null:
			btn.text = "%d) — empty —" % [i + 1]
			btn.disabled = true
		else:
			var price := 0
			if c.has_method("get"): # .tres or dictionaries may expose get()
				price = int(round(c.base_cost * Rarity.multiplier(c.rarity)))
			else:
				price = int(round(c.base_cost * Rarity.multiplier(c.rarity)))
			btn.text = "%d) %s (%s)  %dG" % [i + 1, c.name, c.type_name, price]

		shop_panel.add_child(btn)
		shop_buttons.append(btn)
		y += 32

func bind_shop_controls(shop: Node) -> void:
	ensure_shop()
	if reroll_btn and reroll_btn.pressed.get_connections().size() == 0:
		reroll_btn.pressed.connect(func(): shop.reroll())

	for i in range(shop_buttons.size()):
		var idx := i
		var b := shop_buttons[i]
		if b.disabled: continue
		# Avoid duplicate connections when shop refreshes
		if b.pressed.get_connections().size() == 0:
			b.pressed.connect(func(): shop.buy(idx))

func show_shop_message(msg: String) -> void:
	ensure_shop()
	shop_status.text = msg

func set_inventory_summary(pieces_count: int, tokens_count: int) -> void:
	ensure_shop()
	inv_label.text = "Box: %d/10   Tokens: %d/3" % [pieces_count, tokens_count]
