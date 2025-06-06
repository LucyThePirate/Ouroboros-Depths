extends Node2D

class_name TextComponent

signal finished_playing

@onready var text = $CharacterBody2D/Display/Text as RichTextLabel
@onready var display_location = $CharacterBody2D as CharacterBody2D

const GRAVITY = 600.0
const BOUNCINESS = 0.7
const INITIAL_VELOCITY = 200
const SPREAD = 200

var damage_amount = 0


func _ready():
	display_location.velocity = Vector2(randf_range(-SPREAD, SPREAD), -INITIAL_VELOCITY)


func add_damage(amount: int):
	if amount <= 0:
		return
	damage_amount += amount
	text = "%s" % damage_amount


func _physics_process(delta: float) -> void:
	display_location.velocity.y += GRAVITY * delta
	var collision = display_location.move_and_collide(display_location.velocity * delta)
	if collision:
		display_location.velocity = display_location.velocity.bounce(collision.get_normal())
		display_location.velocity *= BOUNCINESS


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Appear":
		finished_playing.emit()
		queue_free()
