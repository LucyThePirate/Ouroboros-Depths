extends SkillStrategy

var currently_executing := false
var radius = 2
var damage = 0

@export var note_VFX: PackedScene


func _ready():
	super()


func on_stack_execution_started(grid_entity: GridEntity):
	currently_executing = true
	grid_entity.moved.connect(_on_grid_entity_moved.bind(grid_entity))


func on_skill_queued():
	damage += 1
	super()


func _on_grid_entity_moved(_old_coord: Vector2i, new_coord: Vector2i, grid_entity: GridEntity):
	if not currently_executing:
		return
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var offset = -radius + 1
	for i in range(radius * 2 - 1):
		for j in range(radius * 2 - 1):
			var check_coords = grid_coords + Vector2i(offset + i, offset + j)
			if (
				Global.entity_positions.has(check_coords)
				and is_instance_valid(Global.entity_positions[check_coords])
			):
				if Global.entity_positions[check_coords] == grid_entity:
					continue
				grid_entity.hit(Global.entity_positions[check_coords], damage)
				var new_note_VFX = note_VFX.instantiate()
				get_tree().current_scene.add_child(new_note_VFX)
				new_note_VFX.global_position = Global.floors.map_to_local(check_coords)


func on_stack_execution_finished(grid_entity: GridEntity):
	currently_executing = false
	damage = 0


func use_skill(grid_entity: GridEntity):
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	super(grid_entity)
