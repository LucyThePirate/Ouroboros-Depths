extends AnimatedSprite2D


func _ready() -> void:
	$Pop.play()


func _on_animation_looped() -> void:
	hide()


func _on_timer_timeout() -> void:
	queue_free()
