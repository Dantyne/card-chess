extends Node
class_name PieceManager

const MAX_PIECES := 10
var box: Array[PieceRes] = []

func add_piece(p: PieceRes) -> bool:
	if box.size() >= MAX_PIECES:
		return false
	box.append(p)
	return true

func count() -> int:
	return box.size()

func deploy_piece(board: Node, square: Vector2i, piece: PieceRes) -> bool:
	# check empty + on white half
	if board.board[square.x][square.y] != 0:
		return false
	if square.x > 3:
		return false
	board.board[square.x][square.y] = piece.piece_code
	box.erase(piece)
	board.display_board()
	return true
