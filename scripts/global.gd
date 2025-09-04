extends Node

signal turn_passed
signal aggroed_towards_player(grid_entity)
signal deaggroed_towards_player(grid_entity)

@onready var entity_positions = {}

var floors: TileMapLayer
var objects: TileMapLayer
var walls: TileMapLayer

const CELL_SIZE = 100
