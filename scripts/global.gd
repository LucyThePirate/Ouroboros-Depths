extends Node

signal turn_passed
signal next_floor_reached
signal aggroed_towards_player(grid_entity)
signal deaggroed_towards_player(grid_entity)
signal metamorphosis_started
signal metamorphosis_completed
signal UI_opened
signal UI_closed

enum DECKS { BASIC, FUZZER, MUSICIAN, BEAST_TAMER, DEBUG }
@onready var selected_deck := DECKS.BASIC

@onready var entity_positions = {}

@onready var config = ConfigFile.new()
@onready var options_file = "user://options.cfg"

@export var skills: Array[PackedScene]

var seed := 0
var seed_string := ""
var random_seed := true

var floors: TileMapLayer
var objects: TileMapLayer
var walls: TileMapLayer
var darkness: TileMapLayer

const CELL_SIZE = 100

var metamorphosis_reroll_cost = 3

var pause_count := 0


func set_seed(new_seed):
	if new_seed:
		random_seed = false
		seed_string = new_seed
		seed = hash(new_seed)
	else:
		random_seed = true
		seed_string = generate_random_seed()
		seed = hash(seed_string)


func generate_random_seed() -> String:
	var new_seed = ""
	var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	for i in range(8):
		new_seed += characters[randi_range(0, characters.length() - 1)]
	new_seed = new_seed.insert(4, "-")
	return new_seed


func is_turn_based() -> bool:
	if (
		Global.config.has_section_key("Gameplay", "TurnBased")
		and Global.config.get_value("Gameplay", "TurnBased")
	):
		return false
	return true


func load_deck() -> Resource:
	if OS.is_debug_build():
		selected_deck = DECKS.DEBUG
	if Global.config.get_value("Gameplay", "SelectedDeck"):
		selected_deck = Global.config.get_value("Gameplay", "SelectedDeck")
	match selected_deck:
		DECKS.BASIC:
			return load("uid://bveghq3452ke2")  # Basic
		DECKS.FUZZER:
			return load("uid://d3621d3dpr8dj")  # Fuzzer
		DECKS.MUSICIAN:
			return load("uid://cm7tndyucq5bf")  # Musician
		DECKS.BEAST_TAMER:
			return load("uid://xax1raatwfvk")  # Beast Tamer
		DECKS.DEBUG:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -80)
			return load("uid://cpjtvo62gc8ka")  # Debug
		_:
			printerr("UNRECOGNIZED DECK! %s", selected_deck)
	return load("uid://bveghq3452ke2")  # Basic
