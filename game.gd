extends Node

enum MOVES {
	MOVE,
	CAPTURE,
	BORNE_OFF,
	PRISON_ESCAPE
}

@onready
var boardNode = get_node("%Board")

var piece_picked = false
var piece_row: int

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

const dice_faces: Array[String] = [
	"Normals/1",
	"Normals/2",
	"Normals/3",
	"Normals/4",
	"Normals/5",
	"Normals/6"
]

var board: Dictionary = {
	"turn": 1,
	"toPlay": "white"
}

var player: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_game("W", "arst", "W", "art", "B")
	
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func initialize_game(player, nameP1, colorP1, nameP2, colorP2) -> void:
	self.player = player
	initialize_player(nameP1, colorP1)
	initialize_player(nameP2, colorP2)
	boardNode.setup_board(board)

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
	var dice1 = $dice1
	var dice2 = $dice2
	
	# create physics properties for dices
	var physics_mat: PhysicsMaterial = PhysicsMaterial.new()
	dice1.physics_material_override = physics_mat
	dice2.physics_material_override = physics_mat
	
	# reset parameters so no weird spinning or jiggling prevents reroll
	dice1.linear_velocity = Vector3.ZERO
	dice1.angular_velocity = Vector3.ZERO
	dice2.linear_velocity = Vector3.ZERO
	dice2.angular_velocity = Vector3.ZERO
	
	### not sure if needed in final build
	### prevents reroll animation not triggering on multiple clicks
	dice1.freeze = true
	dice2.freeze = true
	await get_tree().physics_frame
	dice1.freeze = false
	dice2.freeze = false
	
	physics_mat.absorbent = false
	physics_mat.friction = 0.5
	physics_mat.bounce = 200
	
	dice1.position = Vector3(0.27, 5.776, 16.46)
	dice2.position = Vector3(0.54, 5.776, 14.36)
	
	await wait(1)
	physics_mat.bounce = 0.5
	await wait(1)
	physics_mat.bounce = 0.2
	await wait(1)
	physics_mat.bounce = 0
	
	#while not (dice1.sleeping and dice2.sleeping):
		#await get_tree().physics_frame
	
	#var die1: int = randi_range(1, 6)
	#var die2: int = randi_range(1, 6)

	dice_roll = get_dies(dice1, dice2)
	var die1: int = dice_roll[0]
	var die2: int = dice_roll[1]
	broadcast_dice_roll.rpc(die1, die2)
	print("Rolled Dice:" + str(die1) + " " + str(die2))
	

@rpc("any_peer", "call_local", "reliable")
func broadcast_dice_roll(die1: int, die2: int) -> void:
	if die1 == die2:
		dice_roll = [die1, die1, die1, die1]
	else:
		dice_roll = [die1, die2]
		
func get_dies(dice1: RigidBody3D, dice2: RigidBody3D):
	var die1: int
	var die2: int
	
	die1 = get_top_face(dice1)
	die2 = get_top_face(dice2)
	return [die1, die2]
		
func get_top_face(dice: RigidBody3D) -> int:
	var best_face_dot: float = -1.0	# worst it can be is upside down
	var best_face: int
	
	for i in range(dice_faces.size()):
		var face: Node3D = dice.get_node_or_null(dice_faces[i])
		
		if face != null:
			var face_dir: Vector3 = face.global_transform.basis.y.normalized()
			var face_dot = face_dir.dot(Vector3.UP)
			
			if (face_dot > best_face_dot):
				best_face_dot = face_dot
				best_face = i + 1		# 0-indexed array
		else:
			print("face node not assigned")
			
	return best_face

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

# should work for both transparent and non transparent pieces when both piece is picked and move is selected
func _on_piece_pressed(_camera, event, _ev_pos, _normal, _sh_idx, color, row):
	if color != player:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not piece_picked:
			var moves = get_legal_moves(color, row)
			piece_picked = true
			piece_row = row
			boardNode.show_possible_moves(moves)
		else:
			if is_move_legal(color, piece_row, row):
				make_move.rpc(MOVES.MOVE, color, piece_row, row)
			piece_picked = false
			boardNode.destroy_possible_moves()

func _on_tigru_button_pressed() -> void:
	pass # Replace with function body.


func _on_end_turn_button_pressed() -> void:
	switch_turn.rpc()
	

func _on_roll_button_pressed() -> void:
	roll_dice()

func _on_dice_1_sleeping_state_changed() -> bool:
	if ($dice1.sleeping):
		return true
	return false


func _on_dice_2_sleeping_state_changed() -> bool:
	if ($dice2.sleeping):
		return true
	return false

func _physics_process(delta: float) -> void:
	pass
