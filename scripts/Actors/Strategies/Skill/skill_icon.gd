extends PanelContainer


func set_icon_texture(new_icon: Texture2D):
	$TextureRect.texture = new_icon


func set_count(new_count := 1):
	if new_count == 1:
		$RichTextLabel.hide()
	else:
		$RichTextLabel.show()
		$RichTextLabel.text = "x%s" % new_count
