extends GPUParticles2D


func _ready() -> void:
	emitting = true


func _on_smoke_sfx_finished() -> void:
	queue_free()
