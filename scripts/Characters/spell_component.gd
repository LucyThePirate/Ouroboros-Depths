extends Node2D

signal entered_range(creature)
signal exited_range(creature)

@export_category("Spell stats")
## Whether or not this spell will follow its parent's transform
@export var is_projectile : bool = true
@export var mana_cost : float = 1.0
@export_range(0, 10, 0.1, "or_greater") var cooldown : float = 1.0
@export_range(0, 100, 1) var max_concurrency : int = 1


func cast(casters_mana : float = 0) -> float :
	if casters_mana < mana_cost:
		# Insufficient mana, return sentinel value to denote a failed casting
		return -1
	
	# Spell successfully cast.
	return mana_cost


func _on_range_hitbox_body_entered(creature: Creature):
	entered_range.emit(creature)


func _on_range_hitbox_body_exited(creature: Creature):
	exited_range.emit(creature)
