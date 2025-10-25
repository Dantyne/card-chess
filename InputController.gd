extends Node
signal piece_selected(pos: Vector2)
signal piece_deselected()
signal move_attempted(from: Vector2, to: Vector2)

@export var CELL_WIDTH := 22
var board_ref: Node2D   # <-- set by Board

var selecting_piece := false
var selected_pos := Vector2(-1, -1)

func process_board_click(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton and event.pressed):
		return false

	if board_ref == null:
		return false  # safety

	# use the SAME mouse position source Board used
	var mx := board_ref.get_global_mouse_position()

	# Right-click cancels
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if selecting_piece:
			selecting_piece = false
			selected_pos = Vector2(-1, -1)
			emit_signal("piece_deselected")
		return true

	if event.button_index == MOUSE_BUTTON_LEFT:
		if _is_out(mx):
			if selecting_piece:
				selecting_piece = false
				selected_pos = Vector2(-1, -1)
				emit_signal("piece_deselected")
			return true

		var col := int(snapped(mx.x, 0) / CELL_WIDTH)
		var row := int(abs(snapped(mx.y, 0)) / CELL_WIDTH)
		var pos := Vector2(row, col)

		if not selecting_piece:
			selecting_piece = true
			selected_pos = pos
			emit_signal("piece_selected", pos)
		else:
			emit_signal("move_attempted", selected_pos, pos)
			selecting_piece = false
			selected_pos = Vector2(-1, -1)
		return true

	return false

func _is_out(p: Vector2) -> bool:
	# matches your Board.is_mouse_out()
	return p.x < 0 or p.x > 176 or p.y > 0 or p.y < -176
