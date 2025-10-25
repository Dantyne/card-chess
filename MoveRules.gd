extends Node
class_name MoveRules

const BOARD_SIZE: int = 8

func raw_moves(piece_abs: int, pos: Vector2, is_white: bool, board: Array) -> Array[Vector2]:
	var t: int = piece_abs
	match t:
		1: return _pawn(pos, is_white, board)
		2: return _bishop(pos, is_white, board)
		3: return _knight(pos, is_white, board)
		4: return _rook(pos, is_white, board)
		5: return _queen(pos, is_white, board)
		6: return _king(pos, is_white, board)
		_: return []

func _in_bounds(p: Vector2) -> bool:
	return p.x >= 0 and p.x < BOARD_SIZE and p.y >= 0 and p.y < BOARD_SIZE

func _is_empty(board: Array, p: Vector2) -> bool:
	return board[int(p.x)][int(p.y)] == 0

func _is_enemy(board: Array, p: Vector2, white_side: bool) -> bool:
	var v: int = board[int(p.x)][int(p.y)]
	if white_side:
		return v < 0
	else:
		return v > 0

func _pawn(pos: Vector2, w: bool, board: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var dir: Vector2 = Vector2(1, 0) if w else Vector2(-1, 0)

	# one step
	var p: Vector2 = pos + dir
	if _in_bounds(p) and _is_empty(board, p):
		out.append(p)
		# two step from start
		var start_row: int = 1 if w else 6
		if int(pos.x) == start_row:
			var p2: Vector2 = pos + dir * 2
			if _in_bounds(p2) and _is_empty(board, p2):
				out.append(p2)

	# diagonals
	for dy in [-1, 1]:
		p = pos + Vector2(dir.x, dy)
		if _in_bounds(p) and _is_enemy(board, p, w):
			out.append(p)
	return out

func _knight(pos: Vector2, w: bool, board: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var dirs: Array[Vector2] = []
	if w:
		dirs = [
			Vector2(2,1), Vector2(2,-1), Vector2(-2,1), Vector2(-2,-1),
			Vector2(1,2), Vector2(1,-2), Vector2(-1,2), Vector2(-1,-2)
		]
	else:
		# your “forward-only” black variant
		dirs = [Vector2(-2,1), Vector2(-2,-1), Vector2(-1,2), Vector2(-1,-2)]

	for d in dirs:
		var p: Vector2 = pos + d
		if _in_bounds(p) and (_is_empty(board, p) or _is_enemy(board, p, w)):
			out.append(p)
	return out

func _ray(pos: Vector2, board: Array, w: bool, dirs: Array[Vector2], limit_steps: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for d in dirs:
		var p: Vector2 = pos
		for i in range(limit_steps):
			p += d
			if not _in_bounds(p):
				break
			if _is_empty(board, p):
				out.append(p)
			elif _is_enemy(board, p, w):
				out.append(p)
				break
			else:
				break
	return out

func _rook(pos: Vector2, w: bool, board: Array) -> Array[Vector2]:
	var dirs: Array[Vector2] = []
	if w:
		dirs = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
	else:
		# black: forward + sideways
		dirs = [Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
	return _ray(pos, board, w, dirs, 2) # your 2-tile cap

func _bishop(pos: Vector2, w: bool, board: Array) -> Array[Vector2]:
	var dirs: Array[Vector2] = []
	if w:
		dirs = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	else:
		# black: forward diagonals only
		dirs = [Vector2(-1,1), Vector2(-1,-1)]
	return _ray(pos, board, w, dirs, 2)

func _queen(pos: Vector2, w: bool, board: Array) -> Array[Vector2]:
	var dirs: Array[Vector2] = []
	if w:
		dirs = [
			Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1),
			Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
		]
	else:
		dirs = [
			Vector2(-1,0), Vector2(0,1), Vector2(0,-1),
			Vector2(-1,1), Vector2(-1,-1)
		]
	return _ray(pos, board, w, dirs, 3) # your 3-tile cap

func _king(pos: Vector2, w: bool, board: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var dirs: Array[Vector2] = [
		Vector2(1,1), Vector2(1,-1), Vector2(-1,-1), Vector2(-1,1),
		Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0)
	]
	for d in dirs:
		var p: Vector2 = pos + d
		if _in_bounds(p) and (_is_empty(board, p) or _is_enemy(board, p, w)):
			out.append(p)
	return out
