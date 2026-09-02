extends Node

class_name ModeSwitcher

var game_scene := load("uid://dnf6sqy5t3iq")  # game_manager.tscn
var tutorial_scene := load("uid://bkcktb2mpmgsc")  # tutorial_level.tscn
var arena_scene := load("uid://d4aptj5nxvsq5")  # arena_test_level.tscn
var title_scene := load("uid://c02to40218vlw")  # title_screen.tscn
var credits_scene := load("uid://dn3wofodnqxg4")  # credits_level.tscn

enum Modes { GAME, TUTORIAL, ARENA, TITLE, CREDITS }
var mode := Modes.TITLE
var current_mode_node: GameMode
var seed := 0


func _ready() -> void:
	_set_node_to_current_mode(get_child(0))


func change_mode(new_mode: Modes):
	var selected_mode
	mode = new_mode
	match new_mode:
		Modes.GAME:
			selected_mode = game_scene
		Modes.TUTORIAL:
			selected_mode = tutorial_scene
		Modes.ARENA:
			selected_mode = arena_scene
		Modes.TITLE:
			selected_mode = title_scene
		Modes.CREDITS:
			selected_mode = credits_scene
		_:
			printerr("UNRECOGNIZED MODE! %s", new_mode)
	current_mode_node.queue_free()
	var new_mode_scene = selected_mode.instantiate()
	_set_node_to_current_mode(new_mode_scene)
	add_child(new_mode_scene)


func reload_current_mode():
	if Global.random_seed:
		Global.set_seed(0)
	change_mode(mode)


func _set_node_to_current_mode(new_mode: GameMode):
	new_mode.requested_mode_switch.connect(change_mode)
	new_mode.requested_reload_current_mode.connect(reload_current_mode)
	current_mode_node = new_mode
