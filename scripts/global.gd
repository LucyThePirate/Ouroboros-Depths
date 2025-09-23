extends Node

signal turn_passed
signal next_floor_reached
signal aggroed_towards_player(grid_entity)
signal deaggroed_towards_player(grid_entity)

@onready var entity_positions = {}

@export var skills: Array[PackedScene]

var floors: TileMapLayer
var objects: TileMapLayer
var walls: TileMapLayer

const CELL_SIZE = 100
