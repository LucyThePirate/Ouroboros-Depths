extends Control

@export_file("*.tscn") var game_scene
@export_file("*.tscn") var tutorial_scene

@onready var config = ConfigFile.new()
@onready var options_file = "user://options.cfg"

@onready var master_volume = $CanvasLayer/Options/CenterContainer/MasterVolume as HSlider
@onready var sfx_volume = $CanvasLayer/Options/CenterContainer2/SFXVolume as HSlider
@onready var music_volume = $CanvasLayer/Options/CenterContainer3/MusicVolume as HSlider
@onready var sfx_tester = $CanvasLayer/Options/CenterContainer2/SFXTester

@onready var load_progress_bar = $CanvasLayer/Loading/VBoxContainer/ProgressBar as ProgressBar
@onready var loading_screen_tip = $CanvasLayer/Loading/VBoxContainer/Tip as RichTextLabel
var tips = [
	"Did you know?: 1 Trillion wasps is a lot of wasps. If you stacked them all on top of each other, they would get really mad!",
	"Chorustone only has a wind-powered facsimile of life, and yet even this is enough for it to drop souls.",
	"Did you know?: Feast your faces on greatest one game!",
	"Thank you for playing! It warms my heart seeing people enjoying all the effort I put into making my game.",
	"Skeletons enjoy such pastimes as prattling about, lobbing femurs at the living, and cackling madly. What a rich and exciting culture!",
]
var loading_scene
enum States { IDLE, LOADING }
var state := States.IDLE


func _ready() -> void:
	ResourceLoader.load_threaded_request(game_scene)
	ResourceLoader.load_threaded_request(tutorial_scene)
	var err = config.load(options_file)
	load_volume_options()
	_on_main_menu_button_pressed()
	loading_screen_tip.text = tips.pick_random()


func _process(delta: float) -> void:
	if state == States.LOADING:
		$CanvasLayer/Loading/CanvasLayer/CursorCollision.position = (
			get_viewport().get_mouse_position()
		)
		var progress = []
		var load_status := ResourceLoader.load_threaded_get_status(loading_scene, progress)
		load_progress_bar.value = progress[0]
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			var fully_loaded_scene = ResourceLoader.load_threaded_get(loading_scene)
			get_tree().change_scene_to_packed(fully_loaded_scene)


func _on_start_tutorial_button_pressed() -> void:
	loading_scene = tutorial_scene
	_start_loading()


func _on_new_game_button_pressed() -> void:
	loading_scene = game_scene
	_start_loading()


func _start_loading():
	$CanvasLayer/Loading.show()
	state = States.LOADING
	$CanvasLayer/Loading/CanvasLayer/TempFloor.process_mode = Node.PROCESS_MODE_DISABLED


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
