extends PanelContainer

class_name SkillIcon

signal clicked
signal left_clicked
signal right_clicked


func set_icon_texture(new_icon: Texture2D):
	$TextureRect.texture = new_icon


func set_count(new_count := 1):
	if new_count == 1:
		$RichTextLabel.hide()
	else:
		$RichTextLabel.show()
		$RichTextLabel.text = "x%s" % new_count


func set_text(new_text := ""):
	$RichTextLabel.text = new_text


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		clicked.emit()
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			left_clicked.emit()
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit()
