extends Node2D

var target: GridEntity

@export var lurch_distance := 40.0
@export var jitter := 40.0
@export var lurch_timer := 1.5

var block_range := 3
@onready var current_lurch_distance := lurch_distance
const LURCH_INCREASE := 0.15
const LURCH_MAX := 100.0
@onready var current_jitter := jitter
const JITTER_INCREASE := 0.25
const JITTER_MAX := 100.0
@onready var current_lurch_timer := lurch_timer
const LURCH_TIMER_DECREASE := 0.01
const LURCH_TIMER_MIN := 0.25
var paused := false
var is_active := false


func _ready() -> void:
	Global.next_floor_reached.connect(queue_free)
	Global.metamorphosis_started.connect(pause_bogo)
	Global.metamorphosis_completed.connect(resume_bogo)
	_find_target()


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	if paused:
		return
	global_position += Vector2(
		randf_range(-current_jitter, current_jitter) * delta,
		randf_range(-current_jitter, current_jitter) * delta
	)
	current_jitter = min(current_jitter + (JITTER_INCREASE * delta), JITTER_MAX)
	current_lurch_distance = min(current_lurch_distance + (LURCH_INCREASE * delta), LURCH_MAX)
	if target:
		%NearbyWarningSFX.pitch_scale = max(
			4 - ((target.global_position - global_position).length() / 200), 0.1
		)


func pause_bogo():
	$Ambiance.stream_paused = true
	paused = true
	$LurchTimer.paused = true
	$MessWithBlocksTimer.paused = true
	current_lurch_distance = lurch_distance
	current_jitter = jitter
	current_lurch_timer = lurch_timer


func resume_bogo():
	$Ambiance.stream_paused = false
	paused = false
	$LurchTimer.paused = false
	$MessWithBlocksTimer.paused = false


func _find_target():
	var entities = get_tree().get_nodes_in_group("GridEntity")
	for entity in entities:
		if entity.is_in_group("Player"):
			target = entity
			%NearbyWarningSFX.play()
			break
	if not (target and target.is_alive()):
		target = entities.pick_random()
		%NearbyWarningSFX.stop()


func _on_mess_with_blocks_timer_timeout() -> void:
	var block_1_coords = Global.floors.local_to_map(global_position)
	var block_2_coords = Global.floors.local_to_map(global_position)
	block_1_coords += Vector2i(
		randi_range(-block_range, block_range), randi_range(-block_range, block_range)
	)
	block_2_coords += Vector2i(
		randi_range(-block_range, block_range), randi_range(-block_range, block_range)
	)
	var block_1 = Global.floors.get_cell_tile_data(block_1_coords) as TileData
	var block_2 = Global.floors.get_cell_tile_data(block_2_coords) as TileData
	if (
		not block_1
		or not block_2
		or block_1.get_custom_data("indestructable")
		or block_2.get_custom_data("indestructable")
	):
		return
	# Swap floors
	var temp_source_id = Global.floors.get_cell_source_id(block_1_coords)
	var temp_atlas_coords = Global.floors.get_cell_atlas_coords(block_1_coords)
	Global.floors.set_cell(
		block_1_coords,
		Global.floors.get_cell_source_id(block_2_coords),
		Global.floors.get_cell_atlas_coords(block_2_coords)
	)
	Global.floors.set_cell(block_2_coords, temp_source_id, temp_atlas_coords)
	# Swap walls
	temp_source_id = Global.walls.get_cell_source_id(block_1_coords)
	temp_atlas_coords = Global.walls.get_cell_atlas_coords(block_1_coords)
	Global.walls.set_cell(
		block_1_coords,
		Global.walls.get_cell_source_id(block_2_coords),
		Global.walls.get_cell_atlas_coords(block_2_coords)
	)
	Global.walls.set_cell(block_2_coords, temp_source_id, temp_atlas_coords)


func _on_lurch_timer_timeout() -> void:
	if target and target.is_alive():
		global_position = global_position.move_toward(
			target.global_position, current_lurch_distance
		)
	else:
		_find_target()
	current_lurch_timer = max(LURCH_TIMER_MIN, current_lurch_timer - LURCH_TIMER_DECREASE)
	$LurchTimer.start(current_lurch_timer)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "spawning":
		is_active = true
		%Hitbox.monitoring = true
		%MessWithBlocksTimer.start()
		%LurchTimer.start()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("GridEntity"):
		body.on_death()
