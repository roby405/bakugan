extends Node3D

const BLACK_PIECE = preload("res://black_piece.tscn")
const WHITE_PIECE = preload("res://white_piece.tscn")


func setup_board(board: Dictionary) -> void:
	for row in board["W"]["pieces"]:
		for _i in range(board["W"]["pieces"][row]):
			add_piece("W", row)
	for row in board["B"]["pieces"]:
		for _i in range(board["B"]["pieces"][row]):
			add_piece("B", row)

### only visually, doesn't manage logic, that should be done by make_move
func add_piece(color: String, row: int, temp = false) -> void:
	var node_name = "%s%d" % [color, row]
	var pos
	if row <= 12:
		pos = get_node("%" + node_name).global_position + Vector3(1.15, 0, 0) * get_node("%" + node_name).get_child_count()
	else:
		pos = get_node("%" + node_name).global_position - Vector3(1.15, 0, 0) * get_node("%" + node_name).get_child_count()
	var new_piece
	if color == "W":
		new_piece = WHITE_PIECE.instantiate()
	else:
		new_piece = BLACK_PIECE.instantiate()
	get_node("%" + node_name).add_child(new_piece)
	if temp:
		
	new_piece.get_node("%Area").input_event.connect(get_parent()._on_piece_pressed.bind(color, row))
	new_piece.global_position = pos

func remove_piece(color: String, row: int) -> void:
	var node_name = "%s%d" % [color, row]
	var removed_piece = get_top_piece(color, row)
	var piece_row = get_node("%" + node_name)
	piece_row.remove_child(removed_piece)
	removed_piece.queue_free()

func move_piece(color: String, row: int, dest: int) -> void:
	var node_name = "%s%d" % [color, row]
	var moved_piece = get_top_piece(color, row)
	var piece_row = get_node("%" + node_name)
	if dest == 0: # prison
		pass
	else:
		var new_piece_row = get_node("%" + node_name)
		piece_row.remove_child(moved_piece)
		new_piece_row.add_child(moved_piece)
		
		# change position code
		if dest <= 12:
			moved_piece.position += Vector3(1.15, 0, 0) * get_node("%" + node_name).get_child_count()
		else:
			moved_piece.position -= Vector3(1.15, 0, 0) * get_node("%" + node_name).get_child_count()

func get_top_piece(color: String, row: int):
	var node_name = "%s%d" % [color, row]
	var piece_row = get_node("%" + node_name)
	var children_count = piece_row.get_child_count()
	return piece_row.get_child(children_count - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
