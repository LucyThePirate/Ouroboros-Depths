extends GameMode

@onready var master_volume = $CanvasLayer/Options/Audio/CenterContainer/MasterVolume as HSlider
@onready var sfx_volume = $CanvasLayer/Options/Audio/CenterContainer2/SFXVolume as HSlider
@onready var music_volume = $CanvasLayer/Options/Audio/CenterContainer3/MusicVolume as HSlider
@onready var sfx_tester = $CanvasLayer/Options/Audio/CenterContainer2/SFXTester

@onready var dungeon_select = $CanvasLayer/NewRun/HContainer/Dungeon/DungeonSelect as TabContainer
@onready var deck_select = $CanvasLayer/NewRun/HContainer/Deck/DeckSelect as TabContainer
@onready var bogosort_timer_options = (
	$CanvasLayer/Options/Gameplay/ScrollContainer/CenterContainer/BogosortTimerOptions
	as OptionButton
)
@onready var turn_based_options = %TurnBasedOptions as OptionButton

@onready var load_progress_bar = $CanvasLayer/Loading/VBoxContainer/ProgressBar as ProgressBar
@onready var loading_screen_tip = $CanvasLayer/Loading/VBoxContainer/Tip as RichTextLabel
var tips = [
	"Did you know?: 1 Trillion wasps is a lot of wasps. If you stacked them all on top of each other, they would get really mad!",
	"Chorustone only has a wind-powered facsimile of life, and yet even this is enough for it to drop souls.",
	"Did you know?: Feast your faces on greatest one game!",
	"Thank you for playing! It warms my heart seeing people enjoying all the effort I put into making my game.",
	"Skeletons enjoy such pastimes as prattling about, lobbing femurs at the living, and cackling madly. What a rich and exciting culture!",
	"Pursued by Bogo? Bogo will respect those who metamorph, try entering your [C]hrysalis to make Bogo cool off!"
]
var loading_scene
enum States { IDLE, LOADING }
var state := States.IDLE


func _ready() -> void:
	Global.config.load(Global.options_file)
	_load_volume_options()
	_load_gameplay_options()
	_on_main_menu_button_pressed()
	loading_screen_tip.text = tips.pick_random()


func _process(_delta: float) -> void:
	if state == States.LOADING:
		$CanvasLayer/Loading/CanvasLayer/CursorCollision.position = (
			get_viewport().get_mouse_position()
		)
		var progress = []
		var load_status := ResourceLoader.load_threaded_get_status(loading_scene, progress)
		load_progress_bar.value = progress[0]
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			var fully_loaded_scene = ResourceLoader.load_threaded_get(loading_scene) as PackedScene
			var change_scene_result = get_tree().change_scene_to_packed(fully_loaded_scene)

			print("Changing scene, result:", change_scene_result)

	else:
		$CanvasLayer/Loading/CanvasLayer/CursorCollision.position = (
			get_viewport().get_mouse_position()
		)
		%TitlePotion.apply_force(
			(
				Vector2(
					%PositionPotionWantsToReturnTO.global_position - %TitlePotion.global_position
				)
				* 5
			)
		)


func _on_new_game_button_pressed() -> void:
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/NewRun.show()
	$CanvasLayer/MainMenuButton.show()
	$CanvasLayer/Disclaimer.hide()


func _start_loading():
	$CanvasLayer/MainMenuButton.hide()
	$CanvasLayer/Loading.show()
	state = States.LOADING
	$CanvasLayer/Loading/CanvasLayer/TempFloor.process_mode = Node.PROCESS_MODE_DISABLED


func _on_options_button_pressed() -> void:
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/Options.show()
	$CanvasLayer/MainMenuButton.show()
	$CanvasLayer/Disclaimer.hide()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_main_menu_button_pressed() -> void:
	Global.config.save(Global.options_file)
	$CanvasLayer/MainMenu.show()
	$CanvasLayer/Loading.hide()
	$CanvasLayer/Options.hide()
	$CanvasLayer/MainMenuButton.hide()
	$CanvasLayer/NewRun.hide()
	$CanvasLayer/Credits.hide()
	$CanvasLayer/Disclaimer.show()


func _load_volume_options():
	if Global.config.has_section_key("Volume", "Master"):
		master_volume.value = Global.config.get_value("Volume", "Master")
	if Global.config.has_section_key("Volume", "SFX"):
		sfx_volume.value = Global.config.get_value("Volume", "SFX")
	if Global.config.has_section_key("Volume", "Music"):
		music_volume.value = Global.config.get_value("Volume", "Music")
	update_audio_busses()


func update_audio_busses():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_volume.value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume.value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume.value)


func _on_master_volume_drag_ended(_value_changed: bool) -> void:
	Global.config.set_value("Volume", "Master", master_volume.value)
	update_audio_busses()


func _on_sfx_volume_drag_ended(_value_changed: bool) -> void:
	Global.config.set_value("Volume", "SFX", sfx_volume.value)
	sfx_tester.play()
	update_audio_busses()


func _on_music_volume_drag_ended(_value_changed: bool) -> void:
	Global.config.set_value("Volume", "Music", music_volume.value)
	update_audio_busses()


func _on_credits_button_pressed() -> void:
	#$CanvasLayer/MainMenu.hide()
	#$CanvasLayer/Credits.show()
	#$CanvasLayer/MainMenuButton.show()
	#$CanvasLayer/Disclaimer.hide()
	requested_mode_switch.emit(ModeSwitcher.Modes.CREDITS)


func _load_gameplay_options():
	if Global.config.has_section_key("Gameplay", "SelectedDungeon"):
		dungeon_select.current_tab = Global.config.get_value("Gameplay", "SelectedDungeon")
	if Global.config.has_section_key("Gameplay", "SelectedDeck"):
		deck_select.current_tab = Global.config.get_value("Gameplay", "SelectedDeck")
	if Global.config.has_section_key("Gameplay", "BogosortTimer"):
		bogosort_timer_options.selected = Global.config.get_value("Gameplay", "BogosortTimer")
	if Global.config.has_section_key("Gameplay", "TurnBased"):
		turn_based_options.selected = Global.config.get_value("Gameplay", "TurnBased")


func _on_bogosort_timer_options_item_selected(index: int) -> void:
	if Global.config:
		Global.config.set_value("Gameplay", "BogosortTimer", index)


func _on_start_run_pressed() -> void:
	if Global.config:
		Global.config.set_value("Gameplay", "SelectedDungeon", dungeon_select.current_tab)
		Global.config.set_value("Gameplay", "SelectedDeck", deck_select.current_tab)
	Global.config.save(Global.options_file)
	if dungeon_select.current_tab == 0:
		requested_mode_switch.emit(ModeSwitcher.Modes.TUTORIAL)
	elif dungeon_select.current_tab == 1:
		Global.set_seed(%SeedLineEdit.text)
		requested_mode_switch.emit(ModeSwitcher.Modes.GAME)
	else:
		requested_mode_switch.emit(ModeSwitcher.Modes.ARENA)


func _on_turn_based_options_item_selected(index: int) -> void:
	if Global.config:
		Global.config.set_value("Gameplay", "TurnBased", index)


func _on_title_potion_body_entered(body: Node) -> void:
	var speed_volume = %TitlePotion.linear_velocity.length() / 500
	speed_volume = clampf(speed_volume, 0.1, 2.0)
	%TitlePotion.material.set(
		"shader_parameter/hue_shift",
		%TitlePotion.material.get("shader_parameter/hue_shift") + speed_volume / 50
	)
	if body is StaticBody2D:
		%BottleClinkSFX.volume_linear = speed_volume
		%BottleClinkSFX.play()
	else:
		%BottleSloshSFX.volume_linear = speed_volume
		%BottleSloshSFX.play()
