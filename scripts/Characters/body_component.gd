class_name Body extends Node


var parts : Dictionary
@export_category("Base Stats")
@export var base_hp : float = 1
@export var base_mp : float = 1
@export_range(0, 5, 0.1, "or_greater") var base_hp_regen : float = 0.1
@export_range(0, 5, 0.1, "or_greater") var base_mp_regen : float = 0.1
@export_range(0, 300, 1, "or_greater") var base_speed : int = 150
@export_range(0, 1, 0.1, "or_greater") var base_appetite : float = 0.1
@export var base_moves : Array[MoveComponent]
@export var starting_parts : Array[part_data]

@export_category("Stat Multipliers")
@export_range(0.01, 2, 0.01, "or_greater") var base_hp_mult : float = 1
@export_range(0.01, 2, 0.01, "or_greater") var base_mp_mult  : float = 1
@export_range(0.01, 2, 0.01, "or_greater") var base_hp_regen_mult  : float = 1
@export_range(0.01, 2, 0.01, "or_greater") var base_mp_regen_mult  : float = 1

var body_owner : Creature

# Actual stats
var max_hp
var current_hp
var max_mp
var current_mp
var hp_regen
var mp_regen
var move_list : Dictionary


func _ready():
	for part in starting_parts:
		add_part(part)
	recalculate_stats()
	# Initialize starting moves
	for move in base_moves:
		add_move(move)
		
	

func add_part(new_part : part_data):
	if parts[new_part.part_type]:
		# Existing part type, replace it
		parts[new_part.part_type] = new_part
	else:
		parts[new_part.part_type] = new_part

		
func recalculate_stats() -> void:
	var hp_percentage = current_hp / max_hp
	var mp_percentage = current_mp / max_mp
	max_hp = base_hp
	max_mp = base_mp
	hp_regen = base_hp_regen
	mp_regen = base_mp_regen
	# Tally up stats from children
	for part in get_node("BodyWindow/VBoxContainer").get_children():
		max_hp += part.base_hp
		max_mp += part.base_mp
		hp_regen += part.base_hp_regen
		mp_regen += part.base_mp_regen
	# Apply multipliers
	max_hp *= base_hp_mult
	max_mp *= base_mp_mult
	hp_regen *= base_hp_regen_mult
	mp_regen *= base_mp_regen_mult
	# Recalculate new current hp/mp now that max mp/hp has changed
	current_hp = max(max_hp * hp_percentage, 1)
	current_mp = max_mp * mp_percentage

func add_move(move : MoveComponent):
	if move.move_name not in move_list:
		move_list[move.move_name] = move
	else:
		move_list[move.move_name].increment()
