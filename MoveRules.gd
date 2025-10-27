extends Node
class_name MoveRules

# ---------------- Helpers ----------------

func _in_bounds(p: Vector2, board: Array) -> bool:
	var x: int = int(p.x)
	var y: int = int(p.y)
	return x >= 0 and x < board.size() \
		and y >= 0 and y < board[x].size()

func _tile(board: Array, p: Vector2) -> int:
	return int(board[int(p.x)][int(p.y)])

func _is_empty(board: Array, p: Vector2) -> bool:
	return _tile(board, p) == 0

func _is_enemy(board: Array, p: Vector2, is_white: bool) -> bool:
	var v: int = _tile(board, p)
	return (is_white and v < 0) or (!is_white and v > 0)

# Generic linear mover (rook/bishop/queen helpers)
func _linear_moves(
	pos: Vector2,
	is_white: bool,
	board: Array,
	dirs: Array[Vector2],
	step_cap: int
) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for d in dirs:
		var p: Vector2 = pos
		for s in range(step_cap):
			p = p + d
			if not _in_bounds(p, board):
				break
			if _is_empty(board, p):
				out.append(p)
			elif _is_enemy(board, p, is_white):
				out.append(p)
				break
			else:
				break
	return out

# ---------------- Piece-specific rules ----------------

func pawn(pos: Vector2, is_white: bool, board: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var dir: Vector2 = (Vector2(1, 0) if is_white else Vector2(-1, 0))

	# One step
	var p1: Vector2 = pos + dir
	if _in_bounds(p1, board) and _is_empty(board, p1):
		out.append(p1)

		# Two-step from start row
	var start_row: int = (1 if is_white else 6)
	if int(pos.x) == start_row:
		var p2: Vector2 = pos + dir * 2
		if _in_bounds(p2, board) and _is_empty(board, p2) and _is_empty(board, p1):
			out.append(p2)

	# Diagonal captures
	for dy in [-1, 1]:
		var atk: Vector2 = pos + Vector2(dir.x, dy)
		if _in_bounds(atk, board) and _is_enemy(board, atk, is_white):
			out.append(atk)

	return out

func knight(pos: Vector2, is_white: bool, board: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var dirs: Array[Vector2] = [
		Vector2(2,1), Vector2(2,-1), Vector2(-2,1), Vector2(-2,-1),
		Vector2(1,2), Vector2(1,-2), Vector2(-1,2), Vector2(-1,-2)
	]
	for d in dirs:
		var p: Vector2 = pos + d
		if _in_bounds(p, board) and (_is_empty(board, p) or _is_enemy(board, p, is_white)):
			out.append(p)
	return out

func bishop(pos: Vector2, is_white: bool, board: Array) -> Array[Vector2]:
	# Your original rules capped sliding to 2
	var dirs: Array[Vector2] = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	return _linear_moves(pos, is_white, board, dirs, 2)

func rook(pos: Vector2, is_white: bool, board: Array) -> Array[Vector2]:
	# Cap 2 like your original game rules
	var dirs: Array[Vector2] = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
	return _linear_moves(pos, is_white, board, dirs, 2)

func queen(pos: Vector2, is_white: bool, board: Array) -> Array[Vector2]:
	# Cap 3 like your original queen
	var dirs: Array[Vector2] = [
		Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1),
		Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
	]
	return _linear_moves(pos, is_white, board, dirs, 3)

func king(pos: Vector2, is_white: bool, board: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var dirs: Array[Vector2] = [
		Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1),
		Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
	]
	for d in dirs:
		var p: Vector2 = pos + d
		if _in_bounds(p, board) and (_is_empty(board, p) or _is_enemy(board, p, is_white)):
			out.append(p)
	return out

# ---------------- Public entry ----------------

func raw_moves(piece_val: int, pos: Vector2, is_white: bool, board: Array) -> Array[Vector2]:
	match piece_val:
		1: return pawn(pos, is_white, board)
		2: return bishop(pos, is_white, board)
		3: return knight(pos, is_white, board)
		4: return rook(pos, is_white, board)
		5: return queen(pos, is_white, board)
		6: return king(pos, is_white, board)
		_: return []
