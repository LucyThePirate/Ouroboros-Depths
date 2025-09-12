extends SkillStrategy

var max_distance = 5

@export var note_VFX: PackedScene
@export var notes: Array[String] = ["C", "D", "E", "F", "G", "A", "B"]
@export var delay := 0.25

@onready var sampler = $SamplerInstrument
@onready var stream_player = $SamplerInstrument/AudioStreamPlayer2D

@onready var sequence: Array[Array] = []
@onready var chord: Array[Vector2i] = []
var is_playing = false


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
	var relative_coord = cursor - grid_coords
	if show_UI:
		stream_player.position = $Cursor.global_position
		sampler.play_note(notes[relative_coord.x % notes.size()], 4 - (relative_coord.y % 4))


func on_stack_execution_started(grid_entity: GridEntity):
	if not is_playing:
		is_playing = true
		replay_sequence(grid_entity)


func use_skill(grid_entity: GridEntity):
	$Cursor.hide()
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var relative_cursor = cursor - grid_coords
	print("Used skill ", name, " towards ", relative_cursor)
	if relative_cursor in chord:
		relative_cursor += Vector2i(randi_range(-1, 1), randi_range(-1, 1))
	chord.append(relative_cursor)
	coord_to_note(relative_cursor, grid_entity)
	super(grid_entity)


func on_stack_execution_finished(grid_entity: GridEntity):
	sequence.append(chord)
	chord = []


func coord_to_note(relative_coord, grid_entity: GridEntity):
	#sampler.play_note(notes[relative_coord.x % notes.size()], 4 - (relative_coord.y % 4))
	var check_coords = Global.floors.local_to_map(grid_entity.global_position) + relative_coord
	#if (
	#Global.entity_positions.has(check_coords)
	#and is_instance_valid(Global.entity_positions[check_coords])
	#):
	#Global.entity_positions[check_coords]._on_hit(grid_entity)
	#var note_rect = Rect2(
	#check_coords * Global.CELL_SIZE, Vector2(Global.CELL_SIZE, Global.CELL_SIZE)
	#)
	#draw_rect(note_rect, Color.RED, true)
	var new_note_VFX = note_VFX.instantiate()
	get_tree().current_scene.add_child(new_note_VFX)
	new_note_VFX.set_note(
		notes[relative_coord.x % notes.size()],
		4 - (relative_coord.y % 4),
		check_coords,
		grid_entity
	)
	new_note_VFX.global_position = Global.floors.map_to_local(check_coords)


func replay_sequence(grid_entity: GridEntity):
	for chord_coord in sequence:
		for relative_coord in chord_coord:
			coord_to_note(relative_coord, grid_entity)
		await get_tree().create_timer(delay).timeout
	is_playing = false


func on_next_floor_reached():
	sequence = []
	super()
