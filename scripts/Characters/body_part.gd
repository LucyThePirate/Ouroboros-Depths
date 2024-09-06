class_name BodySlot extends Node

enum PartTypes {HEAD, TORSO, TORSO_LARGE, LIMBS_ARMS, LIMBS_LEGS_FRONT, LIMBS_LEGS_BACK, TAIL, WINGS}

@export_category("Flavor")
@export var part_name : String = "Default Part"
@export_multiline var description : String = "Meeeat."
@export var part_type : PartTypes = PartTypes.HEAD

@export_category("Base Stats")
@export var base_hp : float = 1
@export var base_mp : float = 1
@export_range(0, 5, 0.1, "or_greater") var base_hp_regen : float = 0.1
@export_range(0, 5, 0.1, "or_greater") var base_mp_regen : float = 0.1
@export_range(0, 300, 1, "or_greater") var base_speed : int = 150
@export_range(0, 1, 0.1, "or_greater") var base_appetite : float = 0.1
@export var base_moves : Array[MoveComponent]
