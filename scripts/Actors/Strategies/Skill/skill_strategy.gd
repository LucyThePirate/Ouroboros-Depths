extends Node2D

class_name SkillStrategy

signal moved_self
signal requested_direction_input(requester)
signal requested_cursor_input
signal direction_set
signal cursor_set

const CELL_SIZE = 100
var initialized = false
var my_turn = false
var grid: TileMap

var floors: TileMapLayer
var walls: TileMapLayer
var objects: TileMapLayer
var entity_positions: Dictionary

var direction: Vector2i
var cursor: Vector2i


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func ready_skill(grid_entity: GridEntity) -> bool:
	use_skill(grid_entity)
	return true


func use_skill(grid_entity: GridEntity) -> bool:
	return false


func get_valid_moves() -> Array:
	var move_options = []
	return move_options


func request_direction():
	requested_direction_input.emit(self)
	await direction_set


func set_direction(newDirection: Vector2i):
	direction = newDirection
	direction_set.emit()


func set_cursor(newCursor: Vector2i):
	cursor = newCursor
