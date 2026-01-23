extends Sprite2D

@export var shield_status: PackedScene

var is_note := false
var note := ""
var octave: int
var check_coords: Vector2i
var grid_parent: GridEntity


func set_note(new_note: String, new_octave: int, new_coords: Vector2i, new_grid_entity: GridEntity):
	is_note = true
	#%Sampler.samplers = new_samplers
	$AnimationPlayer.play("Telegraph")
	note = new_note
	octave = new_octave
	check_coords = new_coords
	grid_parent = new_grid_entity
	$Note.show()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Vanish":
		queue_free()
	if anim_name == "Telegraph":
		$Note.hide()
		$AnimationPlayer.play("Vanish")
		if is_instance_valid(grid_parent) and grid_parent.is_in_group("Player"):
			%Sampler.play_note(note, octave)
		if (
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
			and is_instance_valid(grid_parent)
		):
			if is_note and Global.entity_positions[check_coords] == grid_parent:
				var new_status = shield_status.instantiate() as StatusStrategy
				new_status.power = 1
				add_child(new_status)
				grid_parent.gain_status(new_status)
			else:
				grid_parent.hit(Global.entity_positions[check_coords])
