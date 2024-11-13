extends CharacterBody2D

const speed = 300.0
var main_sm : LimboHSM

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initiate_state_machine()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var direction = Vector2()
	direction.x = Input.get_axis("Left", "Right")
	direction.y = Input.get_axis("Up", "Down")
	if direction:
		if direction.length() > 1:
			direction = direction.normalized()
			velocity = direction * speed

func _initiate_state_machine():
	main_sm = LimboHSM.new()
	add_child(main_sm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(idle_start).call_on_update(idle_update)
	
	main_sm.add_child(idle_state)
	
	main_sm.initial_state = idle_state
	
	main_sm.initialize(self)
	main_sm.set_active(true)
	
	
func idle_start():
	pass
	
func idle_update(delta):
	pass
