extends Node2D

class_name DamageNumberComponent

signal finished_playing

@export var display_text: RichTextLabel
@export var display_location: CharacterBody2D

const GRAVITY = 200.0
const BOUNCINESS = 0.7
const INITIAL_VELOCITY = 300
const TERMINAL_VELOCITY = 300
const SPREAD = 200

var damage_amount = 0
var heal_amount = 0
var base_font_size = 37


func _ready():
	display_location.velocity = Vector2(randf_range(-SPREAD, SPREAD), -INITIAL_VELOCITY)
	global_position += Vector2(randf(), randf())


func add_damage(amount: int):
	$AnimationPlayer.play("MoreDamage")
	$AnimationPlayer.seek(0)
	display_location.position = Vector2(0, -40.0)
	display_location.velocity.y += -INITIAL_VELOCITY / 2.0
	if amount <= 0:
		return
	damage_amount += amount
	var damage_effect_percentage = clampi(damage_amount, 0, 10) / 10.0
	var text_color = Color(1.0, 1.0 - damage_effect_percentage, 1.0 - damage_effect_percentage)
	display_text.self_modulate = text_color
	display_text.text = (
		"[shake rate=%s level=%s][font_size=%s]%s[/font_size][/shake]"
		% [
			damage_effect_percentage * 20,
			damage_effect_percentage * 50,
			base_font_size + (base_font_size * damage_effect_percentage),
			damage_amount
		]
	)


func add_heal(amount: int):
	if amount <= 0:
		return
	$AnimationPlayer.play("MoreDamage")
	$AnimationPlayer.seek(0)
	display_location.position = Vector2(0, -40.0)
	display_location.velocity.y += -INITIAL_VELOCITY / 2.0

	heal_amount += amount
	var heal_effect_percentage = clampi(heal_amount, 0, 10) / 10.0
	var text_color = Color(1.0 - heal_effect_percentage, 1.0, 1.0 - heal_effect_percentage)
	display_text.self_modulate = text_color
	display_text.text = (
		"[wave freq=%s amp=%s][font_size=%s]%s[/font_size][/wave]"
		% [
			heal_effect_percentage * 50,
			heal_effect_percentage * 50,
			base_font_size + (base_font_size * heal_effect_percentage),
			heal_amount
		]
	)


func add_damage_shield(amount: int):
	$AnimationPlayer.play("MoreDamage")
	$AnimationPlayer.seek(0)
	display_location.position = Vector2(0, -40.0)
	display_location.velocity.y += -INITIAL_VELOCITY / 2.0
	if amount <= 0:
		return
	damage_amount += amount
	var damage_effect_percentage = clampi(damage_amount, 0, 10) / 10.0
	var text_color = Color(1.0 - damage_effect_percentage, 1.0 - damage_effect_percentage, 1.0)
	display_text.self_modulate = text_color
	display_text.text = (
		"[shake rate=%s level=%s][font_size=%s]%s[/font_size][/shake]"
		% [
			damage_effect_percentage * 20,
			damage_effect_percentage * 50,
			base_font_size + (base_font_size * damage_effect_percentage),
			damage_amount
		]
	)


func _physics_process(delta: float) -> void:
	display_location.velocity.y += GRAVITY * delta
	display_location.velocity.y = clampf(
		display_location.velocity.y, -TERMINAL_VELOCITY, TERMINAL_VELOCITY
	)
	var collision = display_location.move_and_collide(display_location.velocity * delta)
	if collision:
		display_location.velocity = display_location.velocity.bounce(collision.get_normal())
		display_location.velocity *= BOUNCINESS


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Appear" or anim_name == "MoreDamage":
		finished_playing.emit()
		queue_free()
