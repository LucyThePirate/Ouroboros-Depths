class_name SpellComponent
extends Node2D

signal entered_range(creature)
signal exited_range(creature)

@export_category("Spell stats")
@export var projectile : PackedScene
## Whether or not this spell will follow its parent's transform
@export var follows_parent : bool = true
@export var mana_cost : float = 1.0
@export_range(0, 10, 0.1, "or_greater") var cooldown_time : float = 1.0
@export_range(0, 100, 1) var max_concurrency : int = 1

var is_on_cooldown : bool = false

func cast(caster : Creature) -> float :
	#if casters_mana < mana_cost:
		## Insufficient mana, return sentinel value to denote a failed casting
		#return -1
	
	if is_on_cooldown:
		return -1
	
	if not projectile:
		return -1
	
	# Spell successfully cast.
	var new_projectile = projectile.instantiate()
	new_projectile.position = caster.get_attack_offset().global_position
	new_projectile.rotation = caster.get_attack_offset().rotation
	new_projectile.damage_parent = caster
	get_tree().root.add_child(new_projectile)
	is_on_cooldown = true
	$Cooldown.start(cooldown_time)
	return mana_cost


func _on_range_hitbox_body_entered(creature: Creature):
	entered_range.emit(creature)


func _on_range_hitbox_body_exited(creature: Creature):
	exited_range.emit(creature)


func _on_cooldown_timeout():
	is_on_cooldown = false
