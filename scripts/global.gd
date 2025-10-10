extends Node

signal turn_passed
signal next_floor_reached
signal aggroed_towards_player(grid_entity)
signal deaggroed_towards_player(grid_entity)
signal metamorphosis_started
signal metamorphosis_completed

enum DECKS { BASIC, FUZZER, MUSICIAN }
@onready var selected_deck := DECKS.BASIC
@onready var entity_positions = {}


@onready var config = ConfigFile.new()
@onready var options_file = "user://options.cfg"

@export var skills: Array[PackedScene]

var floors: TileMapLayer
var objects: TileMapLayer
var walls: TileMapLayer
var darkness: TileMapLayer

const CELL_SIZE = 100


func load_deck() -> Resource:
	if Global.config.get_value("Gameplay", "SelectedDeck"):
		selected_deck = Global.config.get_value("Gameplay", "SelectedDeck")
	match selected_deck:
		DECKS.BASIC:
			return load("uid://bveghq3452ke2")  # Basic
		DECKS.FUZZER:
			return load("uid://d3621d3dpr8dj")  # Fuzzer
		DECKS.MUSICIAN:
			return load("uid://cm7tndyucq5bf")  # Musician
		_:
			printerr("UNRECOGNIZED DECK! %s", selected_deck)
	return load("uid://bveghq3452ke2")  # Basic
