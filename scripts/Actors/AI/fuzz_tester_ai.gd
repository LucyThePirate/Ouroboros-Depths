extends CreatureAI




func _ready() -> void:
	super()
	


func _on_detection_radius_body_entered(body: Node2D) -> void:
	if angry_at:
		return
	_update_angry_at(body)
