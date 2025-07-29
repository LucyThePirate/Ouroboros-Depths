extends SkillStrategy

var max_distance = 5

@export var notes: Array[String] = ["C", "D", "E", "F", "G", "A", "B"]

@onready var sampler = $SamplerInstrument


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
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var relative_cursor = cursor - grid_coords
	sampler.play_note(notes[relative_cursor.x % notes.size()], 4 - relative_cursor.y)


func use_skill(grid_entity: GridEntity):
	$Cursor.hide()
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var relative_cursor = cursor - grid_coords
	print("Used skill ", name, " towards ", relative_cursor)
	#cursor
	sampler.play_note(notes[relative_cursor.x % notes.size()], 4 - relative_cursor.y)
	super(grid_entity)
