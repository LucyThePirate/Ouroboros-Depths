class_name Creature
extends CharacterBody2D

enum States {ALIVE, DEAD}

signal creature_entered_attack_range(body)
signal creature_exited_attack_range(body)
signal hit_by(creature)
signal died()

const SPEED = 150.0
const FRICTION_MULTIPLIER = 0.9

@export_category("Creature Stats")
@export var max_health : float = 20
@export var max_mana : float = 20
@export_flags_2d_physics var senses

@export_category("Attacks")
@export var fire_bat : PackedScene

var is_moving = false
@onready var current_attack = %AttackComponent
@onready var health = max_health
var state = States.ALIVE

@onready var inventory = %InventoryComponent
@onready var bodyComponent = %BodyComponent

func _ready():
	inventory.inventory_owner = self
	bodyComponent.body_owner = self
	bodyComponent.toggle_stats_visible(is_in_group("player"))

func _physics_process(_delta):
	if not is_moving:
		velocity = Vector2.ZERO
	move_and_slide()
	is_moving = false


func add_move():
	pass


func remove_move():
	pass
	
	
func add_item(item : item_data):
	inventory.add_item(item)


func can_sense(creature : Creature) -> bool:
	# Check sight
	var space_state = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var query = PhysicsRayQueryParameters2D.create(Vector2(global_position), Vector2(creature.global_position), senses, [self])
	var result = space_state.intersect_ray(query)
	if result and result.collider == creature:
		#print(result.collider.name)
		return true
	return false


## Assumption: direction is a normalized (or less than normalized) vector
func move_in_direction(direction : Vector2):
	velocity = direction * SPEED
	if not current_attack.is_on_standby():
		velocity *= 0.5
	is_moving = true
	
	
func point_towards(look_position : Vector2):
	if not current_attack.is_on_standby():
		return
	var point_direction = (look_position - global_position)
	if point_direction.x:
		$Sprite.flip_h = point_direction.x > 0
	$AttackOffset.look_at(look_position)
	#look_at(look_position)


func attack():
	if current_attack:
		current_attack.attack()


func get_attack_offset() -> Node2D:
	return $AttackOffset


func cast_spell(selected_spell : SpellComponent):
	if not selected_spell:
		return
	selected_spell.cast(self)


func pick_spell_at_random() -> SpellComponent:
	return $AttackOffset/SpellComponent


func hit(damage_amount, damage_parent):
	if damage_parent:
		hit_by.emit(damage_parent)
	health -= max(damage_amount, 0)
	var health_percent = health / max_health
	%Sprite.self_modulate = Color(1, health_percent, health_percent)
	if health <= 0:
		perish()


func perish():
	if state == States.ALIVE:
		state = States.DEAD
		died.emit()
		call_deferred("_disable_collision")
		%AnimationPlayer.play("Die")
		

func is_alive():
	return state == States.ALIVE


func is_doing_something() -> bool:
	if is_moving:
		return true
	return false


func _disable_collision():
	%CreatureCollider.disabled = true


func _on_attack_component_creature_entered_range(body):
	creature_entered_attack_range.emit(body)


func _on_attack_component_creature_exited_range(body):
	creature_exited_attack_range.emit(body)
