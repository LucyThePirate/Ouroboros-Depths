extends GPUParticles2D


func _ready():
	emitting = true
	$StompSound.play()


func _on_stomp_sound_finished() -> void:
	queue_free()
