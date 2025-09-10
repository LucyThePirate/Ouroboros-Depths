extends Sprite2D

var is_note := false
var note := ""
var octave: int
var check_coords: Vector2i
var grid_parent: GridEntity


func set_note(new_note: String, new_octave: int, new_coords: Vector2i, new_grid_entity: GridEntity):
	is_note = true
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
		$SamplerInstrument.play_note(note, octave)
		if (
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
		):
			Global.entity_positions[check_coords]._on_hit(grid_parent)
