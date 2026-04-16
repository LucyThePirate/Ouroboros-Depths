extends Node2D

class_name TextComponent

signal text_submitted
signal text_changed
signal text_cancelled

@onready var text = $Text as RichTextLabel
@onready var text_editor = $LineEdit as LineEdit

var non_player_typing_delay := 0.025
var target_text = ""
var current_text = ""
var text_effect = "%s"


func _ready():
	pass


func initialize(is_player_typed := true):
	if is_player_typed:
		text.text = "[wave amp=50.0 freq=5.0 connected=1]...[/wave]"
		text_editor.grab_focus()
		text_editor.edit()
		#text_editor.keep_editing_on_text_submit = true
	else:
		text.text = ""


#func _process(delta: float) -> void:
#if is_player_typed:
#return
#if current_text.length() < target_text.length():
#pass


func _on_line_edit_text_changed(new_text: String) -> void:
	text.text = new_text
	text_changed.emit()


func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text == "":
		text_submitted.emit()
		queue_free()
		return
	text.text = new_text
	$AnimationPlayer.play("float_away")
	text_submitted.emit()
	text_editor.release_focus()


func set_text(new_text: String, new_text_effect: String = "%s") -> void:
	target_text = new_text
	text_effect = new_text_effect
	text.append_text(new_text_effect)
	current_text = ""
	$TypeDelay.start(non_player_typing_delay)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "float_away" or anim_name == "float_away_error":
		queue_free()


func _on_type_delay_timeout() -> void:
	if current_text.length() < target_text.length():
		current_text += target_text[current_text.length()]
		#text.text = text_effect % current_text
		text.add_text(target_text[current_text.length() - 1])
		text_changed.emit()
	else:
		$TypeDelay.stop()
		$AnimationPlayer.play("float_away")


func set_error_text(new_text: String) -> void:
	text.text = "[color=RED][shake]%s" % new_text
	$AnimationPlayer.play("float_away_error")
