extends Node3D

const BLACK_PIECE = preload("res://black_piece.tscn")
const WHITE_PIECE = preload("res://white_piece.tscn")

var temp_pieces: Array = []

func setup_board(board: Dictionary) -> void:
	for row in board["W"]["pieces"]:
		for _i in range(board["W"]["pieces"][row]):
			add_piece("W", row)
	for row in board["B"]["pieces"]:
		for _i in range(board["B"]["pieces"][row]):
			add_piece("B", row)

func show_possible_moves(moves, color: String):
	for move in moves:
		add_piece(color, move, true)

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
		var mat = new_piece.get_node("%pieceNode").get_node("piece-" + color.to_lower()).get_active_material(0).duplicate() as StandardMaterial3D
		if mat:
			# 1. Turn on transparency mode
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			# 2. Modify the Alpha channel (opacity ranges from 0.0 to 1.0)
			mat.albedo_color.a = 0.7
			
			# Apply the duplicated material back to the mesh
			new_piece.get_node("%pieceNode").get_node("piece-" + color.to_lower()).set_surface_override_material(0, mat)
		temp_pieces.append(new_piece)
	
		
	new_piece.get_node("%Area").input_event.connect(get_parent()._on_piece_pressed.bind(color, row))
	new_piece.global_position = pos

func remove_piece(color: String, row: int) -> void: # dont forget to disconnect signals
	var node_name = "%s%d" % [color, row]
	var removed_piece = get_top_piece(color, row)
	var piece_row = get_node("%" + node_name)
	piece_row.remove_child(removed_piece)
	removed_piece.queue_free()

func remove_temp_pieces() -> void:
	for node in temp_pieces:
		node.queue_free()
	temp_pieces = []

func move_piece(color: String, row: int, dest: int) -> void:
	var node_name = "%s%d" % [color, row]
	var moved_piece = get_top_piece(color, row)
	var piece_row = get_node("%" + node_name)
	#if dest == 0: # prison
		#pass
	#else:
	var new_piece_row = get_node("%" + color + str(dest))
	piece_row.remove_child(moved_piece)
	new_piece_row.add_child(moved_piece)
	
	# change position code
	if dest <= 12:
		moved_piece.global_position = new_piece_row.global_position + Vector3(1.15, 0, 0) * (new_piece_row.get_child_count() - 2)
	else:
		moved_piece.global_position = new_piece_row.global_position - Vector3(1.15, 0, 0) * (new_piece_row.get_child_count() - 2)

func get_top_piece(color: String, row: int):
	var node_name = "%s%d" % [color, row]
	var piece_row = get_node("%" + node_name)
	var children_count = piece_row.get_child_count()
	return piece_row.get_child(children_count - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
