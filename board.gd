extends Node3D

const BLACK_PIECE = preload("res://black_piece.tscn")
const WHITE_PIECE = preload("res://white_piece.tscn")

const INITIAL_WHITE_PLAYER_STATE = {
	"pieces": {
		6: 5,
		8: 3,
		13: 5,
		24: 2
	}
}

const INITIAL_BLACK_PLAYER_STATE = {
	"pieces": {
		19: 5,
		17: 3,
		12: 5,
		1: 2
	}
}

var board = {
	"turn": 1,
	"toPlay": "white"
}

var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

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
	for row in INITIAL_WHITE_PLAYER_STATE:
		for _i in range(INITIAL_WHITE_PLAYER_STATE[row]):
			add_piece("W", row)
	for row in INITIAL_BLACK_PLAYER_STATE:
		for _i in range(INITIAL_BLACK_PLAYER_STATE[row]):
			add_piece("B", row)

### only visually, doesn't manage logic, that should be done by make_move
func add_piece(color: String, row: int) -> void:
	var pos = get_node("%%s%i" % color % row) # +- width * how many children
	var new_piece
	if color == "W":
		new_piece = WHITE_PIECE.instantiate()
	else:
		new_piece = BLACK_PIECE.instantiate()
	new_piece.global_position = pos
	get_node("%%s%i" % color % row).add_child(new_piece)

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
