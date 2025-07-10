extends Node2D

class_name SkillStrategy

signal moved_self
signal requested_direction_input(requester)
signal requested_cursor_input
signal direction_set
signal cursor_set
signal skill_finished

@export var icon: Sprite2D
@export var cooldown_turns := 5
@onready var current_cooldown := 0
@export var max_per_stack := 1
@onready var current_in_stack := 0

var skill_crit := false
var show_UI = true
var grid: TileMap

var floors: TileMapLayer
var walls: TileMapLayer
var objects: TileMapLayer
var entity_positions: Dictionary

var direction: Vector2i
var cursor: Vector2i

enum States { IDLE, AWAITING_DIRECTION, AWAITING_CURSOR, PLAYING_ANIMATION }
var state = States.IDLE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.hide()


func ready_skill(grid_entity: GridEntity) -> bool:
	skill_crit = false
	use_skill(grid_entity)
	return true


func use_skill(grid_entity: GridEntity):
	current_cooldown = cooldown_turns
	current_in_stack = 0
	skill_finished.emit()


func can_use_skill() -> bool:
	if current_cooldown > 0 or current_in_stack >= max_per_stack:
		return false
	return true


func get_valid_moves() -> Array:
	var move_options = []
	return move_options


func request_direction():
	state = States.AWAITING_DIRECTION


func set_direction(newDirection: Vector2i):
	direction = newDirection
	state = States.IDLE


func request_cursor():
	state = States.AWAITING_CURSOR


func move_cursor(moveDirection: Vector2i, grid_entity: GridEntity):
	cursor += moveDirection


func set_cursor(newCursor: Vector2i):
	cursor = newCursor


func decrement_turn_cooldown():
	current_cooldown = maxi(0, current_cooldown - 1)


func increment_in_stack_counter() -> bool:
	if current_in_stack >= max_per_stack:
		return false
	else:
		current_in_stack += 1
		return true
