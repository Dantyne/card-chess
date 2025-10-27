extends Node
class_name ShopManager

# ───────────────────────── Signals ─────────────────────────
signal shop_updated(items: Array[ConsumableBase])
signal purchase_succeeded(item: ConsumableBase)
signal purchase_failed(reason: String)

# ───────────────────────── Config ─────────────────────────
@export var slots: int = 5
@export var reroll_cost: int = 2

# Explicit, inspector-editable paths (adjust in the editor if your hierarchy changes)
@export var board_path: NodePath      = NodePath("../Board")
@export var ui_path: NodePath         = NodePath("../CanvasLayer")
@export var content_db_path: NodePath = NodePath("../ContentDB")
@export var card_mgr_path: NodePath   = NodePath("../CardManager")
@export var piece_mgr_path: NodePath  = NodePath("../PieceManager")
@export var token_mgr_path: NodePath  = NodePath("../TokenManager")

# ───────────────────────── Refs ─────────────────────────
var board: Node = null
var ui: Node = null
var db_node: Node = null
var card_mgr: CardManager = null
var piece_mgr: PieceManager = null
var token_mgr: TokenManager = null

var player                                  # resolved from board.player
var current: Array[ConsumableBase] = []

# ───────────────────────── Lifecycle ─────────────────────────
func _ready() -> void:
	randomize()
	await get_tree().process_frame  # allow siblings' _ready() to run

	# Resolve references safely
	board = get_node_or_null(board_path)
	ui = get_node_or_null(ui_path)
	db_node = get_node_or_null(content_db_path)
	card_mgr  = get_node_or_null(card_mgr_path)
	piece_mgr = get_node_or_null(piece_mgr_path)
	token_mgr = get_node_or_null(token_mgr_path)

	if board == null:
		push_error("ShopManager: Board not found at " + str(board_path))
		return

	# Board exposes a 'player' field
	player = board.get("player")
	if player == null:
		push_error("ShopManager: board.player is null; Board must expose a 'player' field.")
		return

	if db_node == null:
		push_error("ShopManager: ContentDB not found at " + str(content_db_path))
		return

	# Wait until ContentDB has data (it populates in its _ready).
	# Poll a little while to avoid racing the DB.
	var polls: int = 0
	while polls < 60: # ~1s at 60fps
		var cdb := db_node as ContentDB
		if cdb and (cdb.spells.size() > 0 or cdb.pieces.size() > 0 or cdb.tokens.size() > 0):
			break
		polls += 1
		await get_tree().process_frame

	roll_shop()

# ───────────────────────── Public API ─────────────────────────
func reroll() -> void:
	if not player.spend_gold(reroll_cost):
		emit_signal("purchase_failed", "Not enough gold to reroll.")
		return

	if ui and ui.has_method("set_gold"):
		ui.set_gold(int(player.gold))

	roll_shop()

func buy(index: int) -> void:
	if index < 0 or index >= current.size():
		emit_signal("purchase_failed", "Invalid slot.")
		return

	var item: ConsumableBase = current[index]
	if item == null:
		emit_signal("purchase_failed", "That slot is empty.")
		return

	var price: int = _final_price(item)
	if int(player.gold) < price:
		emit_signal("purchase_failed", "Not enough gold.")
		return

	var ok := false
	match item.type_name:
		"Spell":
			ok = card_mgr != null
			if ok:
				card_mgr.deck.append(item as SpellRes)  # add to deck (or hand if you prefer)
		"Piece":
			ok = piece_mgr != null and piece_mgr.add_piece(item as PieceRes)
		"Token":
			ok = token_mgr != null and token_mgr.add_token(item as TokenRes)
		_:
			ok = false

	if not ok:
		emit_signal("purchase_failed", "Inventory full.")
		return

	player.spend_gold(price)
	if ui and ui.has_method("set_gold"):
		ui.set_gold(int(player.gold))

	current.remove_at(index)
	emit_signal("purchase_succeeded", item)
	emit_signal("shop_updated", current)

func on_turn_start_auto_reroll() -> void:
	roll_shop()

# ───────────────────────── Internals ─────────────────────────
func roll_shop() -> void:
	current.clear()
	for i in range(slots):
		current.append(_roll_one_nonnull())
	emit_signal("shop_updated", current)

func _final_price(c: ConsumableBase) -> int:
	var mult: float = Rarity.multiplier(c.rarity)
	return int(round(float(c.base_cost) * mult))

func _roll_one_nonnull() -> ConsumableBase:
	var tries := 0
	while tries < 10:
		var it := _roll_one()
		if it != null:
			return it
		tries += 1

	# Fallback: take first from any pool
	var cdb := db_node as ContentDB
	if cdb:
		if cdb.spells.size() > 0: return cdb.spells[0]
		if cdb.pieces.size() > 0: return cdb.pieces[0]
		if cdb.tokens.size() > 0: return cdb.tokens[0]
	push_error("ShopManager: could not roll a non-null item.")
	return null

func _roll_one() -> ConsumableBase:
	var cdb := db_node as ContentDB
	if cdb == null:
		return null

	# --- rarity by weight ---
	var w := Rarity.shop_chance_weights()
	var total: int = 0
	for k in w.keys():
		total += int(w[k])
	var r: int = randi() % max(1, total)

	var tier: int = Rarity.Tier.COMMON
	var acc: int = 0
	for k in w.keys():
		acc += int(w[k])
		if r < acc:
			tier = int(k)
			break

	# --- choose pool roughly evenly ---
	var pool_pick: int = randi() % 3
	if pool_pick == 0 and cdb.spells.size() > 0:
		var opts: Array = cdb.spells.filter(func(s): return s.rarity == tier)
		if opts.is_empty(): opts = cdb.spells
		return opts[randi() % opts.size()]
	if pool_pick == 1 and cdb.pieces.size() > 0:
		var optp: Array = cdb.pieces.filter(func(p): return p.rarity == tier)
		if optp.is_empty(): optp = cdb.pieces
		return optp[randi() % optp.size()]

	# tokens (fallback)
	if cdb.tokens.size() > 0:
		var optt: Array = cdb.tokens.filter(func(t): return t.rarity == tier)
		if optt.is_empty(): optt = cdb.tokens
		return optt[randi() % optt.size()]

	return null
