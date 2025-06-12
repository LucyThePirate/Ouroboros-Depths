extends Node2D

class_name TextComponent

signal text_submitted
signal text_changed
signal text_cancelled

@onready var text = $Text as RichTextLabel
@onready var text_editor = $LineEdit as LineEdit

const GRAVITY = 600.0
const BOUNCINESS = 0.7
const INITIAL_VELOCITY = 200
const SPREAD = 200

var damage_amount = 0


func _ready():
	text.text = "[wave amp=50.0 freq=5.0 connected=1]...[/wave]"
	text_editor.edit()
	text_editor.keep_editing_on_text_submit = true


func _on_line_edit_text_changed(new_text: String) -> void:
	text.text = new_text
	text_changed.emit()


func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text == "":
		return
	text.text = new_text
	$AnimationPlayer.play("float_away")
	text_submitted.emit()
	text_editor.release_focus()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "float_away":
		queue_free()
