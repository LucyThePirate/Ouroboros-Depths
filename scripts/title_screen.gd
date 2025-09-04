extends Control

@export_file("*.tscn") var game_scene
@export_file("*.tscn") var tutorial_scene

@onready var config = ConfigFile.new()
@onready var options_file = "user://options.cfg"

@onready var master_volume = $CanvasLayer/Options/CenterContainer/MasterVolume as HSlider
@onready var sfx_volume = $CanvasLayer/Options/CenterContainer2/SFXVolume as HSlider
@onready var music_volume = $CanvasLayer/Options/CenterContainer3/MusicVolume as HSlider
@onready var sfx_tester = $CanvasLayer/Options/CenterContainer2/SFXTester


func _ready() -> void:
	var err = config.load(options_file)
	load_volume_options()
	_on_main_menu_button_pressed()


func _on_start_tutorial_button_pressed() -> void:
	$CanvasLayer/Loading.show()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file(tutorial_scene)


func _on_new_game_button_pressed() -> void:
	$CanvasLayer/Loading.show()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file(game_scene)


func _on_options_button_pressed() -> void:
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/Options.show()
	$CanvasLayer/MainMenuButton.show()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_main_menu_button_pressed() -> void:
	config.save(options_file)
	$CanvasLayer/Loading.hide()
	$CanvasLayer/Options.hide()
	$CanvasLayer/MainMenuButton.hide()
	$CanvasLayer/MainMenu.show()


func load_volume_options():
	if config.get_value("Volume", "Master"):
		master_volume.value = config.get_value("Volume", "Master")
	if config.get_value("Volume", "SFX"):
		sfx_volume.value = config.get_value("Volume", "SFX")
	if config.get_value("Volume", "Music"):
		music_volume.value = config.get_value("Volume", "Music")
	update_audio_busses()


func update_audio_busses():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_volume.value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume.value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume.value)


func _on_master_volume_drag_ended(value_changed: bool) -> void:
	config.set_value("Volume", "Master", master_volume.value)
	update_audio_busses()


func _on_sfx_volume_drag_ended(value_changed: bool) -> void:
	config.set_value("Volume", "SFX", sfx_volume.value)
	sfx_tester.play()
	update_audio_busses()


func _on_music_volume_drag_ended(value_changed: bool) -> void:
	config.set_value("Volume", "Music", music_volume.value)
	update_audio_busses()
