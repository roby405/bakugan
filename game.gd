extends Node

enum MOVES {
	MOVE,
	CAPTURE,
	BORNE_OFF,
	PRISON_ESCAPE
}

@onready
var boardNode = get_node("%Board")

var white_bearing_off = false
var black_bearing_off = false
var white_has_in_prison = false
var black_has_in_prison = false

var dice_roll
var die1_used = false
var die2_used = false
var die3_used = false # double only
var die4_used = false # double only
var double = false

var turn = "W"

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
	boardNode.setup_board()

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

func roll_dice() -> void:
	var die1: int = randi_range(1, 6)
	var die2: int = randi_range(1, 6)
	broadcast_dice_roll.rpc(die1, die2)

@rpc("any_peer", "call_remote", "reliable")
func broadcast_dice_roll(die1: int, die2: int) -> void:
	if die1 == die2:
		dice_roll = [die1, die1, die1, die1]
	else:
		dice_roll = [die1, die2]

@rpc("any_peer", "call_remote", "reliable")
func make_move(moveType: MOVES, color: String, row: int, dest: int):
	match moveType:
		MOVES.MOVE:
			if is_move_legal(color, row, dest):
				# captures whatever (runs make_move again)
				board[color][row] -= 1
				if dest == 0: # prison
					pass
				else:
					if not dest in board[color]:
						board[color][dest] = 0
					board[color][dest] += 1
				boardNode.move_piece(color, row, dest)
		MOVES.CAPTURE:
			capture_piece(color, row)
				
		MOVES.BORNE_OFF:
			borne_off_piece(color, row)
		MOVES.PRISON_ESCAPE:
			pass
	
@rpc("any_peer", "call_remote", "reliable")
func switch_turn() -> void:
	if turn == "W":
		turn = "B"
	else:
		turn = "W"
	# some signal gets sent off that switches the hud visibility whatever

func get_legal_moves(color: String, row:int):
	if row == 0:
		pass
	var legal = []
	for dest in range(1, 25):
		if is_move_legal(color, row, dest):
			legal.append(dest)
	return legal

func is_move_legal(color: String, row:int, dest: int) -> bool:
	# dice stuff
	if row < 0 or row > 24: # row 0 is prison
		return false
	if dest < 1 or dest > 24:
		return false
	if row == dest and color == "W" and not white_bearing_off:
		return false
	if row == dest and color == "B" and not black_bearing_off:
		return false
	if color == "W" and dest < row:
		return false
	if color == "B" and dest > row:
		return false
	if color == "W" and white_has_in_prison:
		return false
	if color == "B" and black_has_in_prison:
		return false
	if color == "W" and get_node("%B%i" % dest).get_child_count() > 1:
		return false
	if color == "B" and get_node("%W%i" % dest).get_child_count() > 1:
		return false
	# TODO code for prison escape
	var movement = abs(dest - row)
	if not movement in dice_roll:
		var sum = 0
		for die in dice_roll:
			sum += die
		if sum == 0:
			return false
		if not double and sum != movement:
			return false
		if not double and sum == movement:
			# intermove legality
			var new_row
			if color == "W":
				new_row = row + dice_roll[0]
			else:
				new_row = row - dice_roll[0]
			var found = false
			if color == "W" and get_node("%B%i" % new_row).get_child_count() <= 1:
				found = true
			if color == "B" and get_node("%W%i" % new_row).get_child_count() <= 1:
				found = true
			if not found:
				if color == "W":
					new_row = row + dice_roll[1]
				else:
					new_row = row - dice_roll[1]
				if color == "W" and get_node("%B%i" % new_row).get_child_count() <= 1:
					found = true
				if color == "B" and get_node("%W%i" % new_row).get_child_count() <= 1:
					found = true
				if found != true:
					return false
			
			
		# also check inter moves
		if double:
			var nonzero_die = 0
			for die in dice_roll:
				if die != 0:
					nonzero_die = die
					break
			if movement % nonzero_die != 0:
				return false
			var new_row
			var found = true
			for _i in range(movement/nonzero_die - 1):
				if color == "W":
					new_row = row + nonzero_die
				else:
					new_row = row - nonzero_die
				if color == "W" and get_node("%B%i" % new_row).get_child_count() <= 1:
					found = true and found
				elif color == "B" and get_node("%W%i" % new_row).get_child_count() <= 1:
					found = true and found
				else:
					found = false
					break
			if not found:
				return false
	return true

func capture_piece(color: String, row: int) -> void:
	board[color][row] -= 1
	boardNode.move_piece(color, row, 0)

func get_out_of_prison():
	pass

func borne_off_piece(color: String, row: int):
	pass

func is_white_bearing_off():
	pass

func is_black_bearing_off():
	pass




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_resign_button_pressed() -> void:
	resign.rpc(board.player)

@rpc("any_peer", "call_remote", "reliable")
func resign(color: String) -> void:
	pass




func _on_tigru_button_pressed() -> void:
	pass # Replace with function body.


func _on_end_turn_button_pressed() -> void:
	switch_turn.rpc()
