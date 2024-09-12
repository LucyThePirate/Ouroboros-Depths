class_name MoveStrategy extends Resource

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
@export var move_component : PackedScene

func apply_upgrade(body : Body):
	if not move_component:
		return
	var new_move = move_component.instantiate()
	body.moveList.add_child(new_move)
