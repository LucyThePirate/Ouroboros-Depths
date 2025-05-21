extends Node2D

class_name SkillStrategy

signal moved_self
signal requested_direction_input(requester)
signal requested_cursor_input
signal direction_set
signal cursor_set
signal skill_finished

@export var icon: Sprite2D

const CELL_SIZE = 100
var initialized = false
var my_turn = false
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
	pass


func ready_skill(grid_entity: GridEntity) -> bool:
	use_skill(grid_entity)
	return true


func use_skill(grid_entity: GridEntity) -> bool:
	skill_finished.emit()
	return false


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
