extends SkillStrategy

var max_distance = 3
var shockwave_radius = 2
var damage = 1

@export var DashVFX: PackedScene
@export var StompVFX: PackedScene

@export var note_VFX: PackedScene

var victim_to_throw: GridEntity


func _ready():
	super()


func ready_skill(grid_entity: GridEntity) -> bool:
	# Check for adjacent targets
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var offset = -shockwave_radius + 1
	for i in range(shockwave_radius * 2 - 1):
		for j in range(shockwave_radius * 2 - 1):
			var check_coords = grid_coords + Vector2i(offset + i, offset + j)
			if (
				Global.entity_positions.has(check_coords)
				and is_instance_valid(Global.entity_positions[check_coords])
			):
				if Global.entity_positions[check_coords] == grid_entity:
					continue
				victim_to_throw = Global.entity_positions[check_coords]
				break
	if victim_to_throw:
		request_cursor()
		if show_UI:
			$Cursor.global_position = grid_entity.global_position
			cursor = Global.floors.local_to_map(grid_entity.global_position)
			$Cursor.show()
		return false
	else:
		use_skill(grid_entity)
		return true


func move_cursor(moveDirection: Vector2i, grid_entity: GridEntity):
	cursor += moveDirection
	#cursor = cursor.clampi(-max_distance, max_distance)
	$Cursor.global_position = Global.floors.map_to_local(cursor)


func use_skill(grid_entity: GridEntity):
	$Cursor.hide()
	if not victim_to_throw:
		super(grid_entity)
		return
	victim_to_throw.warp(cursor)
	var new_stomp_VFX = StompVFX.instantiate()
	add_child(new_stomp_VFX)
	new_stomp_VFX.global_position = victim_to_throw.global_position
	var grid_coords = Global.floors.local_to_map(victim_to_throw.global_position)
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
	if skill_crit:
		shockwave_radius -= 1
		damage -= 1
	victim_to_throw = null
	super(grid_entity)
