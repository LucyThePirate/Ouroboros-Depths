extends Node2D

enum States {STANDBY, STARTING_UP, ATTACK_DURATION, ATTACK_COOLDOWN}

@export_category("Timers")
@export var startup_time : float = 0.25
@export var attack_duration_time : float = 0.5
@export var cooldown_time : float = 0.75

var _state = States.STANDBY

func _process(delta):
	print(_state)


func attack():
	if _state == States.STANDBY:
		_state = States.STARTING_UP
		if startup_time > 0:
			$StartupTimer.start(startup_time)
		else: # no startup time, just go straight to the attack
			_on_startup_timer_timeout()


func _on_startup_timer_timeout():
	if _state == States.STARTING_UP:
		_state = States.ATTACK_DURATION
		_set_hitbox_enabled(true)
		if attack_duration_time > 0:
			$AttackDurationTimer.start(attack_duration_time)
		else: # no duration time, check for any hits this frame then go straight to cooldown
			_check_for_hits()
			_on_attack_duration_timer_timeout()


func _on_attack_duration_timer_timeout():
	if _state == States.ATTACK_DURATION:
		_state = States.ATTACK_COOLDOWN
		_set_hitbox_enabled(false)
		if cooldown_time > 0:
			$CooldownTimer.start(cooldown_time)
		else: # no cooldown time, can go to standby right away
			_on_cooldown_timer_timeout()


func _on_cooldown_timer_timeout():
	if _state == States.ATTACK_COOLDOWN:
		_state = States.STANDBY


func _check_for_hits():
	for body in $Area2D.get_overlapping_bodies():
		if body.has_method("hit"):
			body.hit()


func _set_hitbox_enabled(hitbox_enable : bool):
	$Area2D.visible = hitbox_enable
	$Area2D.monitoring = hitbox_enable
