extends Node2D

class_name DamageNumberComponent

signal finished_playing

@export var display_text: RichTextLabel
@export var display_location: CharacterBody2D

const GRAVITY = 600.0
const BOUNCINESS = 0.7
const INITIAL_VELOCITY = 200
const SPREAD = 200

var damage_amount = 0


func _ready():
	display_location.velocity = Vector2(randf_range(-SPREAD, SPREAD), -INITIAL_VELOCITY)


func add_damage(amount: int):
	$AnimationPlayer.play("MoreDamage")
	$AnimationPlayer.seek(0)
	display_location.position = Vector2(0, -40.0)
	display_location.velocity = Vector2(randf_range(-SPREAD, SPREAD), -INITIAL_VELOCITY)
	if amount <= 0:
		return
	damage_amount += amount
	display_text.text = "%s" % damage_amount


func _physics_process(delta: float) -> void:
	display_location.velocity.y += GRAVITY * delta
	var collision = display_location.move_and_collide(display_location.velocity * delta)
	if collision:
		display_location.velocity = display_location.velocity.bounce(collision.get_normal())
		display_location.velocity *= BOUNCINESS


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Appear" or anim_name == "MoreDamage":
		finished_playing.emit()
		queue_free()
