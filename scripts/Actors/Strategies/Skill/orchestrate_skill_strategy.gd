extends SkillStrategy

var max_distance = 5

@export var note_VFX: PackedScene
@export var notes: Array[String] = ["C", "D", "E", "F", "G", "A", "B"]
@export var delay := 0.25

@onready var sequence: Array[Array] = []
@onready var chord: Array[Vector2i] = []
var is_playing = false


func ready_skill(grid_entity: GridEntity) -> bool:
	request_cursor()
	return false


func move_cursor(moveDirection: Vector2i, grid_entity: GridEntity):
	cursor += moveDirection
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var relative_coord = cursor - grid_coords
	if show_UI:
		%Sampler.play_note(notes[relative_coord.x % notes.size()], 4 - (relative_coord.y % 4))


func set_cursor_position(new_position: Vector2i, grid_entity: GridEntity):
	cursor = new_position
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var relative_coord = new_position - grid_coords
	if show_UI:
		%Sampler.play_note(notes[relative_coord.x % notes.size()], 4 - (relative_coord.y % 4))


func on_stack_execution_started(grid_entity: GridEntity):
	if not is_playing:
		is_playing = true
		replay_sequence(grid_entity)


func use_skill(grid_entity: GridEntity):
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var relative_cursor = cursor - grid_coords
	if relative_cursor in chord:
		relative_cursor += Vector2i(randi_range(-1, 1), randi_range(-1, 1))
	chord.append(relative_cursor)
	coord_to_note(relative_cursor, grid_entity)
	super(grid_entity)


func on_stack_execution_finished(grid_entity: GridEntity):
	sequence.append(chord)
	chord = []


func coord_to_note(relative_coord, grid_entity: GridEntity):
	var check_coords = Global.floors.local_to_map(grid_entity.global_position) + relative_coord
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
