extends SkillStrategy

@export var patience_status: PackedScene
@export var note_VFX: PackedScene
@export var power := 1
var base_radius = 2
var damage = 0
var current_patience: StatusStrategy


func _ready():
	super()


func on_skill_queued():
	if not current_patience:
		current_patience = patience_status.instantiate() as StatusStrategy
		current_patience.power = power
		add_child(current_patience)
		gained_status.emit(current_patience)


func use_skill(grid_entity: GridEntity):
	print("Used skill ", name, " with patience at:", current_patience.power)
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var total_radius = base_radius + floor(current_patience.power / 4.0)
	if total_radius <= 2:
		$YellShort.play()
	elif total_radius <= 3:
		$YellMedium.play()
	elif total_radius <= 4:
		$YellLong.play()
	else:
		$YellMax.play()
		$Scream.global_position = grid_entity.global_position
		$AnimationPlayer.play("Scream")
		total_radius = 5
	var offset = -total_radius + 1
	for i in range(total_radius * 2 - 1):
		for j in range(total_radius * 2 - 1):
			var check_coords = grid_coords + Vector2i(offset + i, offset + j)
			var new_note_VFX = note_VFX.instantiate()
			get_tree().current_scene.add_child(new_note_VFX)
			new_note_VFX.global_position = Global.floors.map_to_local(check_coords)
			if (
				Global.entity_positions.has(check_coords)
				and is_instance_valid(Global.entity_positions[check_coords])
			):
				if Global.entity_positions[check_coords] == grid_entity:
					continue
				Global.entity_positions[check_coords]._on_hit(
					grid_entity, damage + (total_radius - 1)
				)
	super(grid_entity)


func on_stack_execution_finished(grid_entity: GridEntity):
	if current_patience:
		current_patience.on_status_ended()
