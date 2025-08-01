extends Node2D

class_name GridEntity

signal grid_entity_initialized
signal moved(old_coord: Vector2i, new_coord: Vector2i)
signal opened_door(cell_coord)
signal pushed_object(object_coord, direction)
signal spawn_tile(tile_coord)
signal hurt
signal fell_off_map
signal descended
signal died
signal performed_action

@onready var thump_sound = $Thump
@onready var glass_thump_sound = $GlassThump
@onready var plant_thump_sound = $PlantThump

@onready var step_sound = $Step
@onready var grass_step_sound = $GrassStep
@onready var water_step_sound = $WaterStep

@onready var door_open = $DoorOpen

@onready var health_component = $UI/HealthComponent as HealthComponent
@onready var status_component = $UI/StatusManagerComponent as StatusManagerComponent
@onready var turn_component = $TurnComponent as TurnComponent

const CELL_SIZE = 100
var initialized = false
var my_turn = false
var moved_by_skill := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	turn_component.turn_ended.connect(status_component.on_turn_ended)


func initialize():
	if initialized:
		return
	# Snap to grid
	global_position = Global.floors.map_to_local(Global.floors.local_to_map(global_position))
	initialized = true
	grid_entity_initialized.emit()
	Global.entity_positions[Global.floors.local_to_map(global_position)] = self


func get_skills() -> Array[Node]:
	return Debug.find_children_in_group(self, "Skill", true)


func move(direction: Vector2i) -> bool:
	if not initialized:
		return false

	var old_coords = Global.floors.local_to_map(global_position)
	var grid_coords = old_coords + direction
	var floor_data = Global.floors.get_cell_tile_data(grid_coords)

	# Test for other bodies
	if Global.entity_positions.has(grid_coords):
		hit(Global.entity_positions[grid_coords])
		performed_action.emit()
		return false

	# Object interaction
	var wall_data = Global.walls.get_cell_tile_data(grid_coords)
	if wall_data:
		if wall_data.get_custom_data("is_door"):
			opened_door.emit(grid_coords)
			door_open.play()
			performed_action.emit()
			return false
		if wall_data.get_custom_data("is_pushable"):
			play_thump_sound(wall_data.get_custom_data("material"))
			pushed_object.emit(grid_coords, direction)
			performed_action.emit()
			return false
		if wall_data.get_custom_data("is_solid"):
			play_thump_sound(wall_data.get_custom_data("material"))
			return false

	# Movement
	moved.emit(old_coords, grid_coords)
	Global.entity_positions[grid_coords] = self
	Global.entity_positions.erase(Global.floors.local_to_map(global_position))
	global_position += Vector2(direction) * CELL_SIZE
	performed_action.emit()
	if not floor_data:
		fell_off_map.emit()
	else:
		play_walk_sound(floor_data.get_custom_data("material"))
	return true


func warp(position: Vector2i) -> bool:
	print("warping to:", position)
	if not initialized:
		return false

	var old_coords = Global.floors.local_to_map(global_position)
	var grid_coords = position
	var floor_data = Global.floors.get_cell_tile_data(grid_coords)

	# Test for other bodies
	if Global.entity_positions.has(grid_coords):
		hit(Global.entity_positions[grid_coords])
		performed_action.emit()
		return false

	# Check for walls
	var wall_data = Global.walls.get_cell_tile_data(grid_coords)
	if wall_data and wall_data.get_custom_data("is_solid"):
		play_thump_sound(wall_data.get_custom_data("material"))
		return false

	# Movement
	moved.emit(old_coords, grid_coords)
	Global.entity_positions[grid_coords] = self
	Global.entity_positions.erase(Global.floors.local_to_map(global_position))
	global_position = Vector2(position) * CELL_SIZE + (Vector2(1, 1) * (CELL_SIZE / 2))
	performed_action.emit()
	if not floor_data:
		fell_off_map.emit()
	else:
		play_walk_sound(floor_data.get_custom_data("material"))
	return true


func get_valid_moves(allow_moving_into_entities = false) -> Array:
	var move_options = []
	if not initialized:
		return move_options
	for direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var grid_coords = Global.floors.local_to_map(global_position) + direction
		if is_obstructed(grid_coords, true, allow_moving_into_entities):
			continue

		# Nothing blocking movement in this direction.
		move_options.append(direction)
	return move_options


func is_obstructed(
	grid_coords: Vector2i, check_floor = true, allow_moving_into_entities = false
) -> bool:
	if check_floor:
		var floor_data = Global.floors.get_cell_tile_data(grid_coords)
		if not floor_data:
			return true

	var wall_data = Global.walls.get_cell_tile_data(grid_coords)
	if wall_data and wall_data.get_custom_data("is_solid"):
		return true

	if not allow_moving_into_entities:
		if Global.entity_positions.has(grid_coords):
			return true
	return false


func try_attacking(entity):
	for direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var grid_coords = Global.floors.local_to_map(global_position) + direction

		# Test for other bodies
		if (
			Global.entity_positions.has(grid_coords)
			and Global.entity_positions[grid_coords] == entity
		):
			hit(entity)
			return true
	return false


func hit(entity):
	if entity and entity.has_method("_on_hit"):
		entity._on_hit(self)


func _on_hit(attacker, damage := 1):
	if self == attacker:
		#$Error.play()
		return
	else:
		print(self.name, "was hit by:", attacker.name)
		damage = status_component.modify_damage(damage)
		health_component.deal_damage(damage)
		$Hit.play()
		hurt.emit(attacker)


func heal(heal_amount := 1):
	health_component.heal(heal_amount)


func inflict_status(condition: StatusStrategy):
	pass


func play_walk_sound(material):
	match material:
		"grass":
			grass_step_sound.play()
		"water":
			water_step_sound.play()
		_:
			step_sound.play()


func play_thump_sound(material):
	match material:
		"stone":
			thump_sound.play()
		"glass":
			glass_thump_sound.play()
		"plant":
			plant_thump_sound.play()
		_:
			thump_sound.play()


func on_death() -> void:
	Global.entity_positions.erase(Global.floors.local_to_map(global_position))
	died.emit()


func is_alive() -> bool:
	if health_component.health > 0:
		return true
	else:
		return false


func is_on_floor() -> bool:
	var grid_coords = Global.floors.local_to_map(global_position)
	var floor_data = Global.floors.get_cell_tile_data(grid_coords)
	if not floor_data:
		return false
	return true


func is_on_path_down() -> bool:
	var grid_coords = Global.floors.local_to_map(global_position)
	var floor_data = Global.floors.get_cell_tile_data(grid_coords)
	if not floor_data or not floor_data.get_custom_data("is_path_down"):
		return false
	return true


func _on_skill_stack_component_gained_status(status: StatusStrategy) -> void:
	gain_status(status)


func gain_status(status: StatusStrategy):
	status_component.add_status(status)
