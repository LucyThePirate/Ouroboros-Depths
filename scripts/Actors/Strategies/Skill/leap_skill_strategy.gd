extends SkillStrategy

var max_distance = 5

@export var DashVFX: PackedScene


func ready_skill(grid_entity: GridEntity) -> bool:
	request_cursor()
	if show_UI:
		$Cursor.global_position = grid_entity.global_position
		cursor = Global.floors.local_to_map(grid_entity.global_position)
		$Cursor.show()
	return false


func move_cursor(moveDirection: Vector2i, grid_entity: GridEntity):
	cursor += moveDirection
	$Cursor.global_position = Global.floors.map_to_local(cursor)


func use_skill(grid_entity: GridEntity):
	$Cursor.hide()
	print("Used skill ", name, " towards ", cursor)
	if grid_entity.warp(cursor):
		moved_self.emit()
		var new_dash_VFX = DashVFX.instantiate() as GPUParticles2D
		new_dash_VFX.emitting = true
		add_child(new_dash_VFX)
		new_dash_VFX.global_position = grid_entity.global_position
	super(grid_entity)
