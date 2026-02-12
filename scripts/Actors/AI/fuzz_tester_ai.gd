extends CreatureAI


func _ready() -> void:
	super()


func _on_detection_radius_body_entered(body: Node2D) -> void:
	if can_aggro_against(body) and body not in potential_targets:
		potential_targets.append(body)
