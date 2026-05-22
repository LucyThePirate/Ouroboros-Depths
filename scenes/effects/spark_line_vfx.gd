extends Line2D


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "ShowSparkLine":
		queue_free()


func _ready() -> void:
	%ZapSFX.global_position = global_position
	%ZapSFX.play()
