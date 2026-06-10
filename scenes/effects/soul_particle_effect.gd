# based loosely on https://www.youtube.com/watch?v=Bhc_EBasycY
extends CharacterBody2D

class_name SoulParticleEffect

signal reached_target
signal particles_finished

@export var target: Node2D

const MAX_POINTS = 50
const ROTATION_SPEED_INCREASE_AMOUNT = 0.5
const DAMPING_INCREASE_RATE = 0.01
var rotation_speed = 0.25
var speed = 800
var damping = 0

enum States { FLOATING, TARGET_REACHED }
var state = States.FLOATING


func _process(delta: float) -> void:
	delta *= 5
	var target_position: Vector2
	if not target:
		target_position = get_global_mouse_position()
	else:
		target_position = target.global_position
	match state:
		States.FLOATING:
			rotate_to_target(target_position, delta)
			velocity *= (1 - damping)
			damping = move_toward(damping, 1, delta * DAMPING_INCREASE_RATE)
			velocity += global_transform.basis_xform(Vector2.RIGHT) * delta * speed
			rotation_speed += delta * ROTATION_SPEED_INCREASE_AMOUNT
			move_and_slide()
			%Trail.add_point(global_position)
			if %Trail.points.size() > MAX_POINTS:
				%Trail.remove_point(0)
			if (global_position - target_position).length_squared() <= 500:
				if velocity.length_squared() <= 90000:
					state = States.TARGET_REACHED
					reached_target.emit()
					%ExplosionParticles.global_position = target_position
					%ExplosionParticles.emitting = true
		States.TARGET_REACHED:
			%ExplosionParticles.global_position = target_position
			%Trail.add_point(global_position)
			if %Trail.points.size() > MAX_POINTS:
				%Trail.remove_point(0)


func rotate_to_target(target_position, delta):
	var direction = target_position - global_position
	var angle_to = transform.x.angle_to(direction)
	rotate(sign(angle_to) * min(delta * rotation_speed, abs(angle_to)))


func _on_explosion_particles_finished() -> void:
	particles_finished.emit()
	queue_free()
