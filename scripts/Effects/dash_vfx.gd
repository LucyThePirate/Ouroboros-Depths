extends GPUParticles2D


func _on_ready():
	emitting = true
	$DashSFX.global_position = global_position


func _on_timer_timeout() -> void:
	queue_free()
