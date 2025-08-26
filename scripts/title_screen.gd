extends Control

@export_file("*.tscn") var game_scene
@export_file("*.tscn") var tutorial_scene


func _ready() -> void:
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
	$CanvasLayer/Loading.hide()
	$CanvasLayer/Options.hide()
	$CanvasLayer/MainMenuButton.hide()
	$CanvasLayer/MainMenu.show()
