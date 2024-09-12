class_name Body extends Node


var parts : Dictionary
@export_category("Base Stats")
@export var base_hp : float = 1
@export var base_mp : float = 1
@export_range(0, 5, 0.1, "or_greater") var base_hp_regen : float = 0.1
@export_range(0, 5, 0.1, "or_greater") var base_mp_regen : float = 0.1
@export_range(0, 300, 1, "or_greater") var base_speed : int = 150
@export_range(0, 1, 0.1, "or_greater") var base_appetite : float = 0.1
@export var base_moves : Array[MoveStrategy]
@export var starting_parts : Array[PartStrategy]
@export var max_skill_points : int = 1

@export_category("Stat Multipliers")
@export_range(0.01, 2, 0.01, "or_greater") var base_hp_mult : float = 1
@export_range(0.01, 2, 0.01, "or_greater") var base_mp_mult  : float = 1
@export_range(0.01, 2, 0.01, "or_greater") var base_hp_regen_mult  : float = 1
@export_range(0.01, 2, 0.01, "or_greater") var base_mp_regen_mult  : float = 1

var body_owner : Creature

@onready var moveList = $MoveList
@onready var HPText = $StatBar/GridContainer/HealthText
@onready var MPText = $StatBar/GridContainer/ManaText

# Actual stats
@onready var max_hp = base_hp
@onready var current_hp = max_hp
@onready var max_mp = base_mp
@onready var current_mp = max_mp
@onready var hp_regen = base_hp_regen
@onready var mp_regen = base_mp_regen
var move_list : Dictionary
@onready var skill_points = max_skill_points


func _ready():
	for part in starting_parts:
		add_part(part)
	# Initialize starting moves
	for move in base_moves:
		add_move(move)
		
	update_stat_text()

func add_part(new_part : PartStrategy):
	if new_part.part_type in parts:
		# Existing part type, replace it
		parts[new_part.part_type].revert_upgrade(self)
		parts[new_part.part_type] = new_part
		apply_upgrade(new_part)
	else:
		parts[new_part.part_type] = new_part
		apply_upgrade(new_part)

		
func apply_upgrade(part : PartStrategy) -> void:
	var hp_percentage = min(current_hp / max_hp, 1)
	var mp_percentage = min(current_mp / max_mp, 1)
	part.apply_upgrade(self)
	# Recalculate new current hp/mp now that max mp/hp has changed
	current_hp = max(max_hp * hp_percentage, 1)
	current_mp = max_mp * mp_percentage
	

func add_move(move : MoveStrategy):
	move.apply_upgrade(self)
	#if move.move_id not in move_list:
		#move_list[move.move_id] = move
	#else:
		#move_list[move.move_id].move_quantity += 1


func update_stat_text() -> void:
	HPText.text = "HP: " + str(current_hp) + "/" + str(max_hp)
	MPText.text = "MP: " + str(current_mp) + "/" + str(max_mp)
