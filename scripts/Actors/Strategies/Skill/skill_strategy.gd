extends Node2D

class_name SkillStrategy

signal moved_self

const CELL_SIZE = 100
var initialized = false
var my_turn = false
var grid: TileMap

var floors: TileMapLayer
var walls: TileMapLayer
var objects: TileMapLayer
var entity_positions: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func use_skill(direction: Vector2i, grid_entity: GridEntity) -> bool:
	return false


func get_valid_moves() -> Array:
	var move_options = []
	return move_options
