extends Node2D



func _ready() -> void:
	$Splash.emitting = true


func _on_timer_timeout() -> void:
	queue_free()
