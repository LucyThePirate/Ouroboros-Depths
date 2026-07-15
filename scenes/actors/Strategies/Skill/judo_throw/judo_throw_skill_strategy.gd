extends SkillStrategy

var max_distance = 3
var damage = 1
var shockwave_radius = 2
@export var attack_height: float = 50
@export var preview_line_cuts: int = 15

@export var DashVFX: PackedScene
@export var StompVFX: PackedScene

@export var note_VFX: PackedScene

var victim_to_throw: GridEntity
var wall_to_throw: bool
var wall_to_throw_coords: Vector2i


func _ready():
	super()


func ready_skill(grid_entity: GridEntity) -> bool:
	%GrabSFX.play()
	%AnimationPlayer.play("RESET")
	%GrabLineVFX.clear_points()
	# Check for adjacent targets
	var grid_coords = grid_entity.grid_coords
	var adjacent = [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 0)
	]
	var max_line_points = 4
	for a in adjacent:
		var check_coords = grid_coords + a
		%GrabLineVFX.add_point(Global.floors.map_to_local(check_coords))
		if %GrabLineVFX.points.size() > max_line_points:
			%GrabLineVFX.remove_point(0)
		if (
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
		):
			if Global.entity_positions[check_coords] == grid_entity:
				continue
			victim_to_throw = Global.entity_positions[check_coords]
			break
		if (
			Global.walls.get_cell_tile_data(check_coords)
			and Global.walls.get_cell_tile_data(check_coords).get_custom_data("is_pushable")
		):
			wall_to_throw = true
			wall_to_throw_coords = check_coords
			break
		await get_tree().create_timer(0.025).timeout
	%AnimationPlayer.play("fade_line")
	if victim_to_throw:
		%GrabSuccessSFX.play()
		%GrabCursor.global_position = victim_to_throw.global_position
		%GrabCursor.show()
		request_cursor()
		if show_UI:
			cursor = victim_to_throw.grid_coords
			_set_preview_on(true, victim_to_throw.global_position)
		return false
	elif wall_to_throw:
		%GrabSuccessSFX.play()
		%GrabCursor.global_position = Global.walls.map_to_local(wall_to_throw_coords)
		%GrabCursor.show()
		request_cursor()
		if show_UI:
			cursor = wall_to_throw_coords
			_set_preview_on(true, %GrabCursor.global_position)
		return false
	else:
		use_skill(grid_entity)
		return true


func move_cursor(moveDirection: Vector2i, _grid_entity: GridEntity):
	cursor += moveDirection
	if show_UI:
		_set_preview_on(true, %GrabCursor.global_position)


func use_skill(grid_entity: GridEntity):
	%GrabCursor.hide()
	_set_preview_on(false, grid_entity.global_position)
	if not victim_to_throw and not wall_to_throw:
		super(grid_entity)
		return
	%ThrowSFX.play()
	if victim_to_throw:
		victim_to_throw.warp(cursor)
	elif wall_to_throw:
		Tiles.move_wall(wall_to_throw_coords, cursor)
	_spawn_shockwave_at_coords(cursor, grid_entity)

	victim_to_throw = null
	wall_to_throw = false
	super(grid_entity)


func _spawn_shockwave_at_coords(grid_coords: Vector2i, grid_entity: GridEntity):
	var new_stomp_VFX = StompVFX.instantiate()
	add_child(new_stomp_VFX)
	new_stomp_VFX.global_position = Global.floors.map_to_local(grid_coords)
	var offset = -shockwave_radius + 1
	for i in range(shockwave_radius * 2 - 1):
		for j in range(shockwave_radius * 2 - 1):
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
				grid_entity.hit(Global.entity_positions[check_coords], damage)


func _set_preview_on(preview_on: bool, starting_position: Vector2):
	%PreviewLine.visible = preview_on
	$Line2D.points[0] = starting_position
	#%PreviewLine.points[0] = grid_entity.global_position
	if preview_on:
		_update_attack_preview(starting_position)


func _update_attack_preview(starting_position: Vector2):
	var cursor_coords = Global.walls.map_to_local(cursor)
	var mid_point = (starting_position + cursor_coords) / 2
	$Line2D.points[1] = mid_point - Vector2(0, attack_height)
	$Line2D.points[2] = cursor_coords
	$PreviewLine.clear_points()
	for cut in range(preview_line_cuts):
		var line_progress = cut / float(preview_line_cuts)
		var q0 = $Line2D.points[0].lerp($Line2D.points[1], line_progress)
		var q1 = $Line2D.points[1].lerp($Line2D.points[2], line_progress)
		var r = q0.lerp(q1, line_progress)
		$PreviewLine.add_point(r)
