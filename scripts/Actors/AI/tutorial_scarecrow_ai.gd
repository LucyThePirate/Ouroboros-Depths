extends StationaryAI

@export var text_scene: PackedScene
@export_multiline var text_to_display: String
var current_text


func _on_detection_radius_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if not current_text:
			var new_text_component = text_scene.instantiate() as TextComponent
			add_child(new_text_component)
			new_text_component.global_position = global_position
			new_text_component.set_text(text_to_display)
			new_text_component.text_changed.connect(visual._on_talked)
			current_text = new_text_component
