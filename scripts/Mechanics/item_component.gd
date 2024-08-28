extends RigidBody2D

## Whether or not this item will jump around on its own.
@export var is_haunted : bool = true
@export var item_data : item_data

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fling()
	if is_haunted:
		$HauntedTimer.start()
	print("this is:", item_data.name)
	$Label.text = item_data.name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func fling(fling_direction : Vector2 = Vector2(), fling_strength : float = 30) -> void:
	if fling_direction == Vector2.ZERO:
		# Pick a random direction to fling
		fling_direction = Vector2(1, 0).rotated(randf_range(0, 2*PI))
	apply_impulse(fling_direction * fling_strength)
	return


func _on_haunted_timer_timeout() -> void:
	fling()


func _on_mouse_entered() -> void:
	$Label.show()


func _on_mouse_exited() -> void:
	$Label.hide()
