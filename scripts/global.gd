extends Node

signal turn_passed

@onready var entity_positions = {}

var floors: TileMapLayer
var objects: TileMapLayer
var walls: TileMapLayer

const CELL_SIZE = 100
