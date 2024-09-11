class_name MoveComponent extends Resource

enum Activation {
	ACTIVE = 0,
	PASSIVE = 1,
}

enum CostTypes {
	MANA = 0,
	MAX_MANA = 1,
	SKILL_POINT = 2,
	HEALTH = 3,
	MAX_HEALTH = 4,
	INNATE = 5,
}

@export_category("Flavor")
@export var move_name : String = "Default Move"
@export_multiline var description : String = "Standard stuff.\nWhaddya know?"
@export var move_id : int = -1

@export_category("Learning Stats")
## How many different sources this creature has learned this move from
@export var move_quantity : int = 0
@export var opportunity_cost_quantity : int = 0
@export var opportunity_cost_type : CostTypes = CostTypes.INNATE

@export_category("Move Stats")
@export var activation_type : Activation = Activation.ACTIVE
@export var cast_cost_quantity : int = 0
@export var cast_cost_type : CostTypes = CostTypes.MANA
@export var spell_component : PackedScene
@export var cooldown_time : float = 0.5

func cast():
	
	pass
