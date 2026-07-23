extends SkillStrategy

var max_distance = 3

@export var DashVFX: PackedScene
@export var attack_height: float = 50
@export var preview_line_cuts: int = 15


func ready_skill(grid_entity: GridEntity) -> bool:
	request_cursor()
	return false


func move_cursor(moveDirection: Vector2i, grid_entity: GridEntity):
	cursor += moveDirection
	#cursor = cursor.clampi(-max_distance, max_distance)
	if show_UI:
		_set_preview_on(true, grid_entity)


func set_cursor_position(new_position: Vector2i, grid_entity: GridEntity):
	super(new_position, grid_entity)
	if show_UI:
		_set_preview_on(true, grid_entity)


func use_skill(grid_entity: GridEntity):
	_set_preview_on(false, grid_entity)
	print("Used skill ", name, " towards ", cursor)
	if grid_entity.warp(cursor):
		moved_self.emit()
		var new_dash_VFX = DashVFX.instantiate() as GPUParticles2D
		new_dash_VFX.emitting = true
		add_child(new_dash_VFX)
		new_dash_VFX.global_position = grid_entity.global_position
	super(grid_entity)


func _set_preview_on(preview_on: bool, grid_entity: GridEntity):
	%PreviewLine.visible = preview_on
	%Line2D.clear_points()
	$Line2D.add_point(Global.floors.map_to_local(grid_entity.grid_coords))
	if preview_on:
		_update_attack_preview(grid_entity)


func _update_attack_preview(grid_entity: GridEntity):
	var cursor_coords = Global.walls.map_to_local(cursor)
	var mid_point = (Global.floors.map_to_local(grid_entity.grid_coords) + cursor_coords) / 2
	$Line2D.add_point(mid_point - Vector2(0, attack_height))
	$Line2D.add_point(cursor_coords)
	$PreviewLine.clear_points()
	for cut in range(preview_line_cuts):
		var line_progress = cut / float(preview_line_cuts)
		var q0 = $Line2D.points[0].lerp($Line2D.points[1], line_progress)
		var q1 = $Line2D.points[1].lerp($Line2D.points[2], line_progress)
		var r = q0.lerp(q1, line_progress)
		$PreviewLine.add_point(r)
