extends Node3D

const BLACK_PIECE = preload("res://black_piece.tscn")
const WHITE_PIECE = preload("res://white_piece.tscn")

var INITIAL_WHITE_PLAYER_STATE: Dictionary = {
	"pieces": {
		6: 5,
		8: 3,
		13: 5,
		24: 2
	}
}

var INITIAL_BLACK_PLAYER_STATE: Dictionary = {
	"pieces": {
		19: 5,
		17: 3,
		12: 5,
		1: 2
	}
}

var board: Dictionary = {
	"turn": 1,
	"toPlay": "white"
}

var player: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_game("W", "arst", "W", "art", "B")

func initialize_game(player, nameP1, colorP1, nameP2, colorP2) -> void:
	self.player = player
	initialize_player(nameP1, colorP1)
	initialize_player(nameP2, colorP2)
	setup_board()

func initialize_player(name: String, color: String) -> void:
	if color == "W":
		var new_player = INITIAL_WHITE_PLAYER_STATE
		new_player["color"] = color
		new_player["name"] = name
		board["W"] = new_player
	else:
		var new_player = INITIAL_BLACK_PLAYER_STATE
		new_player["color"] = color
		new_player["name"] = name
		board["B"] = new_player

func setup_board() -> void:
	for row in INITIAL_WHITE_PLAYER_STATE["pieces"]:
		for _i in range(INITIAL_WHITE_PLAYER_STATE["pieces"][row]):
			add_piece("W", row)
	for row in INITIAL_BLACK_PLAYER_STATE["pieces"]:
		for _i in range(INITIAL_BLACK_PLAYER_STATE["pieces"][row]):
			add_piece("B", row)

### only visually, doesn't manage logic, that should be done by make_move
func add_piece(color: String, row: int) -> void:
	var node_name = "%s%d" % [color, row]
	print(node_name)
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
	new_piece.global_position = pos

func remove_piece(color: String, row: int) -> void:
	board[color][row] -= 1
	var removed_piece = get_top_piece(color, row)
	var piece_row = get_node("%%s%i" % color % row)
	piece_row.remove_child(removed_piece)
	removed_piece.queue_free()

func move_piece(color: String, row: int, dest: int) -> void:
	var moved_piece = get_top_piece(color, row)
	var piece_row = get_node("%%s%i" % color % row)
	board[color][row] -= 1
	if dest == 0: # prison
		pass
	else:
		if not dest in board[color]:
			board[color][dest] = 0
		board[color][dest] += 1
		var new_piece_row = get_node("%%s%i" % color % dest)
		piece_row.remove_child(moved_piece)
		new_piece_row.add_child(moved_piece)
		
		# change position code

func get_top_piece(color: String, row: int):
	var piece_row = get_node("%%s%i" % color % row)
	var children_count = piece_row.get_child_count()
	return piece_row.get_child(children_count - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
