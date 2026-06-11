@tool
extends GameMode

@export var boulder_splash: PackedScene
@export var spawn_smoke_scene: PackedScene
@export var player_scene: PackedScene
@export var creature_scene: Array[PackedScene]
@export var challenge_rating_capacity := 15.0
var current_challenge_rating := 0.0
@export var bogosort_scene: PackedScene
var bogo_egg_scene = preload("uid://dvtenp8g812ei")
var bogo_egg: BraindeadAI

@export var generator: GenerationStrategy
@export var spawn_creatures := true
@export var tutorial_level := false
@export var is_arena := false

@onready var pause_screen := %PauseScreen
@onready var pause_button := %PauseButton

#region Fog
@onready var fog = $Fog
@onready var darkness = $Darkness as TileMapLayer
#endregion

#region Terrain generation and Tiles
var root_node: Branch
var tile_size: int = 100
@onready var floors: TileMapLayer = $Floors
@onready var walls = $Walls as TileMapLayer
@onready var path_tile := [3, Vector2i(1, 3)]
@onready var room_floor_tile := [3, Vector2i(0, 3)]
@onready var glass_wall_tile := [2, Vector2i(3, 0)]
@onready var stone_wall_tile := [2, Vector2i(1, 0)]
@onready var boulder_object_tile := [2, Vector2i(3, 2)]
@onready var tall_tree_wall_tile := [3, Vector2i(3, 2)]
@onready var small_tree_wall_tile := [3, Vector2i(2, 3)]
@onready var clover_decor_tile := [3, Vector2i(3, 1)]
@onready var grass_floor_tile := [3, Vector2i(1, 3)]
@onready var stone_floor_tile := [2, Vector2i(0, 1)]
@onready var water_floor_tile := [3, Vector2i(0, 0)]
@onready var lilly_decor_tile := [3, Vector2i(3, 0)]
@onready var ice_floor_tile := [3, Vector2i(2, 1)]
@onready var bogo_tile := [3, Vector2i(2, 1)]
@onready var door_horizontal_tile := [2, Vector2i(1, 2)]
@onready var door_vertical_tile := [2, Vector2i(2, 2)]
@onready var stairs_up_tile := [2, Vector2i(0, 2)]
@onready var stairs_down_tile := [2, Vector2i(0, 3)]
@onready var lock_tile := [2, Vector2i(4, 2)]
@onready var fog_tile := [3, Vector2i(1, 1)]

var paths: Array = []
var noise
var rng
var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
#endregion

@onready var turn_queue: Array[TurnComponent]
var ready_for_next_turn = true
var turn_counter = 0
var current_floor := 0
var player

var angry_at_player = 0


func _ready():
	if Engine.is_editor_hint():
		%Fog.hide()
		%Darkness.hide()
		return
	%Fog.show()
	%Darkness.show()
	_on_unpaused()
	if tutorial_level:
		Global.metamorphosis_completed.connect(_on_metamorphosis_tutorial_completed)
	#get_window().focus_exited.connect(_on_paused)
	#get_tree().get_root().focus_exited.connect(_on_paused)
	#get_viewport().gui_focus_changed.connect(_on_paused)
	if not Global.UI_closed.is_connected(_on_unpaused):
		Global.UI_closed.connect(_on_unpaused)
		Global.UI_opened.connect(_on_paused)
		Global.aggroed_towards_player.connect(add_to_angry_at_player_list)
		Global.deaggroed_towards_player.connect(remove_from_angry_at_player_list)
	Global.entity_positions = {}
	Global.metamorphosis_reroll_cost = 3
	$CanvasLayer/DeathScreen.hide()
#region Setting up RNG and dungeon generation
	if (
		$Floors.get_used_cells().size() > 0
		and $Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])
	):
		# There already is a level, no need to generate
		Global.floors = floors
		Global.walls = walls
		_initialize_fog()
		player = (
			spawn_entity(
				$Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0], player_scene
			)
			as Player
		)
		_initialize_entities()
		return
	# Else, no existing level, generate
	generator.initialize(current_floor, floors, walls, fog)
	generator.generate_level()
	for extra_node in generator.extra_nodes:
		extra_node.reparent(self)
		if extra_node is CreatureAI:
			extra_node.grid_entity.global_position = extra_node.global_position - Vector2(50, 50)
			#_initialize_entity(extra_node.grid_entity)

	_initialize_fog()
	spawn_bogo_egg()
	if not player:
		player = (
			spawn_entity(
				$Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0], player_scene
			)
			as Player
		)
	player.grid_entity.warp($Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0])
	Global.entity_positions[$Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0]] = (
		player.grid_entity
	)

	for random_monster_tile in walls.get_used_cells_by_id(
		Tiles.random_monster_tile[0], Tiles.random_monster_tile[1]
	):
		walls.set_cell(random_monster_tile, -1)
		spawn_monster_at_coords(random_monster_tile)

	for i in range(int(10 + current_floor) / 2):
		try_spawning_random_monster(false)

	_initialize_entities()


func _initialize_fog():
	darkness.clear()
	if is_arena:
		return
	darkness.set_pattern(walls.get_used_rect().position, walls.get_pattern(walls.get_used_cells()))
	for x in Global.walls.get_used_rect().size.x:
		for y in Global.walls.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + Global.walls.get_used_rect().position.x,
				y + Global.walls.get_used_rect().position.y
			)
			darkness.set_cell(tile_position, fog_tile[0], fog_tile[1])

	#for tile_position in fog.get_used_cells():
	#var empty_tile = (
	#(Global.walls.get_cell_tile_data(tile_position) == null)
	#and (Global.floors.get_cell_tile_data(tile_position) == null)
	#)
	#if empty_tile:
	#fog.set_cell(tile_position, -1)
	#darkness.set_cell(tile_position, -1)

	Global.darkness = darkness
	_update_fog(
		$Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0],
		$Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0]
	)


func add_to_angry_at_player_list(_grid_entity):
	angry_at_player += 1
	_update_dynamic_music()


func remove_from_angry_at_player_list(_grid_entity):
	angry_at_player -= 1
	_update_dynamic_music()


func _update_dynamic_music():
	if not $GhostQuiet:
		return
	$CanvasLayer/AggroCount.text = "Angry: %s" % angry_at_player
	if angry_at_player <= 0:
		$GhostQuiet.volume_db = 0
		$GhostBattle.volume_db = -50
	else:
		$GhostQuiet.volume_db = -50
		$GhostBattle.volume_db = 0


func _redraw_map():
	if tutorial_level:
		requested_mode_switch.emit(ModeSwitcher.Modes.TITLE)
		return
	Global.next_floor_reached.emit()
	current_floor += 1
	$CanvasLayer/ColorRect/FloorLabel.text = "Floor: %s" % current_floor
	$AnimationPlayer.play("floor_text")
	for entity in get_tree().get_nodes_in_group("GridEntity") as Array[GridEntity]:
		if not entity.is_in_group("Player"):
			entity.on_death(true)
	angry_at_player = 0
	current_challenge_rating = 0.0
	Global.floors.clear()
	Global.walls.clear()
	fog.clear()
	_update_fog(
		Global.floors.local_to_map(player.grid_entity.global_position),
		Global.floors.local_to_map(player.grid_entity.global_position)
	)
	_ready()


#endregion


func _initialize_entities():
	for entity in get_tree().get_nodes_in_group("GridEntity"):
		_initialize_entity(entity)
	process_turn()


func _initialize_entity(new_entity: GridEntity):
	if new_entity.initialized:
		return
	new_entity.opened_door.connect(_open_door)
	new_entity.pushed_object.connect(_push_tile)
	new_entity.spawn_tile.connect(spawn_tile)
	new_entity.spawn_wall.connect(spawn_wall)
	new_entity.spawn_entity.connect(spawn_entity_from_creature.bind(new_entity))
	new_entity.died.connect(_on_entity_died.bind(new_entity))
	turn_queue.push_back(new_entity.turn_component)
	new_entity.turn_component.turn_ended.connect(_entity_finished_turn.bind(new_entity))
	if not new_entity.is_in_group("Player"):
		#new_entity.health_component.max_health += floori(
		#new_entity.health_component.max_health * current_floor * 0.25
		#)
		#new_entity.health_component.health = new_entity.health_component.max_health
		#new_entity.health_component._update_health_bar()
		pass
	else:
		player.grid_entity.moved.connect(_update_fog)
		player.grid_entity.died.connect(_on_player_died)
		player.descended.connect(_redraw_map)
	new_entity.initialize()


func _update_fog(old_coords: Vector2i, new_coords: Vector2i):
	if is_arena:
		return
	#print("Old: %s, new: %s" % [old_coords, new_coords])
	#if old_coords == new_coords:
	#return
	var light_radius = 7
	var tile_light = {}
	var terrain_rect = Global.floors.get_used_rect()

	for x in terrain_rect.size.x:
		for y in terrain_rect.size.y:
			var tile = Vector2i(terrain_rect.position.x + x, terrain_rect.position.y + y)
			Global.darkness.set_cell(tile, fog_tile[0], fog_tile[1])
			tile_light[tile] = 0
	#Global.darkness.set_pattern(
	#walls.get_used_rect().position, walls.get_pattern(walls.get_used_cells())
	#)
	var marked_tiles = [new_coords]
	var adjacent_tiles = [
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 0),
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1)
	]
	for a_t in adjacent_tiles:
		marked_tiles.append(new_coords + a_t)
		tile_light[new_coords + a_t] = light_radius - 1
	tile_light[new_coords] = light_radius
	while not marked_tiles.is_empty():
		var checking_tile = marked_tiles.pop_front()
		var current_light = tile_light[checking_tile]
		Global.darkness.set_cell(checking_tile, -1)
		fog.set_cell(checking_tile, -1)
		if current_light <= 1:
			continue

		for a_t in adjacent_tiles:
			var tile = a_t + checking_tile
			if tile not in tile_light or tile_light[tile] >= current_light:
				continue
			tile_light[tile] = current_light - 1
			var wall_tile = Global.walls.get_cell_tile_data(checking_tile)
			if wall_tile and wall_tile.get_custom_data("occluding"):
				continue
			marked_tiles.append(tile)


func spawn_entity(grid_coordinate: Vector2i, entity_scene: PackedScene):
	var new_entity = entity_scene.instantiate()
	new_entity.global_position = floors.map_to_local(grid_coordinate)
	add_child(new_entity)
	#print("Spawned %s at: %s" % [new_entity.name, grid_coordinate])
	return new_entity


func process_turn():
	if not Global.is_turn_based():
		turn_counter += 1
		if spawn_creatures and (turn_counter % 10) == 0:
			try_spawning_random_monster(true)
		return

	if turn_queue.size() <= 0:
		turn_counter += 1
		if spawn_creatures and (turn_counter % 5) == 0:
			try_spawning_random_monster(true)
		#print(turn_counter)
		for turn_component in get_tree().get_nodes_in_group("TurnComponent"):
			turn_queue.push_back(turn_component)
	var current_entity = turn_queue.pop_front()
	if current_entity:
		current_entity.take_turn()
	else:
		process_turn()
	Global.turn_passed.emit()


func spawn_monster_at_coords(grid_coordinate: Vector2i):
	var new_entity = spawn_entity(grid_coordinate, creature_scene.pick_random())
	current_challenge_rating += new_entity.grid_entity.challenge_rating


func try_spawning_random_monster(initialize_entity := true):
	if current_challenge_rating < challenge_rating_capacity + current_floor * 3:
		var grid_coordinate = Global.floors.get_used_cells().pick_random()
		if not _is_obstructed(grid_coordinate):
			var new_entity = (
				spawn_entity(grid_coordinate, creature_scene.pick_random()) as CreatureAI
			)
			current_challenge_rating += new_entity.grid_entity.challenge_rating
			if initialize_entity:
				_initialize_entity(new_entity.grid_entity)
				if is_arena:
					new_entity._update_angry_at(player.grid_entity)
				if is_arena or not Global.darkness.get_cell_tile_data(grid_coordinate):
					var new_smoke = spawn_smoke_scene.instantiate()
					new_smoke.global_position = Global.floors.map_to_local(grid_coordinate)
					add_child(new_smoke)


func spawn_bogo_egg():
	if tutorial_level:
		return
	var grid_coordinate = (
		Global.floors.get_used_cells_by_id(bogo_tile[0], bogo_tile[1], 1).pick_random()
	)
	bogo_egg = spawn_entity(grid_coordinate, bogo_egg_scene)
	bogo_egg.egg_died.connect(_on_bogo_timer_timeout)
	bogo_egg.egg_timer_expired.connect(_on_bogo_timer_timeout)


func _entity_finished_turn(grid_entity: GridEntity):
	#ready_for_next_turn = true
	#if grid_entity != player and not grid_entity.is_in_darkness():
	#await get_tree().create_timer(0.05).timeout
	#await grid_entity.turn_component.turn_ended
	if Global.is_turn_based():
		process_turn()
	elif grid_entity.is_in_group("Player"):
		process_turn()


func _open_door(door_coords):
	walls.set_cell(door_coords, -1)


func _push_tile(tile_coords, direction):
	if Global.entity_positions.has(tile_coords + direction):
		return
	Tiles.move_wall(tile_coords, tile_coords + direction)


func spawn_tile(tile_coords, tile_data := [-1, Vector2i(-1, -1)]):
	var existing_tile = floors.get_cell_tile_data(tile_coords)
	if existing_tile and existing_tile.get_custom_data("indestructable"):
		return
	#Global.floors.set_cell(tile_coords, 2, Vector2i(0, 1))
	if not existing_tile:
		floors.set_cell(tile_coords, Tiles.Floors["dirt"][0], Tiles.Floors["dirt"][1])
	else:
		floors.set_cell(tile_coords, tile_data[0], tile_data[1])


func spawn_wall(tile_coords, tile_data := [-1, Vector2i(-1, -1)]):
	var existing_wall = walls.get_cell_tile_data(tile_coords)
	var existing_tile = floors.get_cell_tile_data(tile_coords)
	if existing_wall and existing_wall.get_custom_data("indestructable"):
		return
	if not existing_tile:
		floors.set_cell(tile_coords, Tiles.Floors["dirt"][0], Tiles.Floors["dirt"][1])
	elif (
		existing_tile.get_custom_data("is_liquid")
		and not existing_tile.get_custom_data("indestructable")
	):
		floors.set_cell(tile_coords, Tiles.Floors["dirt"][0], Tiles.Floors["dirt"][1])
		var splashVFX = boulder_splash.instantiate()
		walls.add_child(splashVFX)
		splashVFX.global_position = Global.floors.map_to_local(tile_coords)
	else:
		walls.set_cell(tile_coords, tile_data[0], tile_data[1])


func spawn_entity_from_creature(
	grid_coordinate: Vector2i,
	entity_type: GridEntity.Species,
	summoning_skill: SkillStrategy,
	summoning_entity: GridEntity
):
	var summon_locations = [grid_coordinate]
	for adjacent_tile in Global.floors.get_surrounding_cells(grid_coordinate):
		summon_locations.append(adjacent_tile)
	for summon_coords in summon_locations:
		if not _is_obstructed(summon_coords, true):
			var entity_scene = CreatureRepository.creatures[entity_type]
			var new_entity = spawn_entity(summon_coords, entity_scene)
			_initialize_entity(new_entity.grid_entity)
			new_entity._update_visibility()
			new_entity.grid_entity.challenge_rating = 0.0
			new_entity.grid_entity.soul_count = 0
			summoning_skill.on_entity_summoned(summoning_entity, new_entity)
			if is_arena or not Global.darkness.get_cell_tile_data(summon_coords):
				var new_smoke = spawn_smoke_scene.instantiate()
				new_smoke.global_position = Global.floors.map_to_local(summon_coords)
				add_child(new_smoke)
			return


func _is_obstructed(tile_coords, requires_floor := false) -> bool:
	var floor_tile = Global.floors.get_cell_tile_data(tile_coords)
	if not floor_tile and requires_floor:
		return true

	var wall_tile = Global.walls.get_cell_tile_data(tile_coords)
	if wall_tile and wall_tile.get_custom_data("is_solid"):
		return true

	#var object_tile = Global.walls.get_cell_tile_data(tile_coords)
	#if object_tile and object_tile.get_custom_data("is_solid"):
	#return true

	if Global.entity_positions.has(tile_coords):
		return true
	return false


func _on_entity_died(is_despawning, grid_entity: GridEntity):
	current_challenge_rating -= grid_entity.challenge_rating
	if is_arena or tutorial_level:
		return
	if not is_despawning and grid_entity.challenge_rating > 0:
		Global.walls.set_cell(generator.stairs_down_location, -1)


func _on_player_died(_despawning) -> void:
	if not is_arena:
		for tile in Global.floors.get_used_cells():
			Global.darkness.set_cell(tile, -1)
	$Fog.hide()
	$Darkness.hide()
	$CanvasLayer/DeathScreen/VBoxContainer/FloorReached.text = ("Floor Reached: %s" % current_floor)
	$CanvasLayer/DeathScreen/VBoxContainer/Kills.text = "Kills: %s" % player.grid_entity.kills
	$CanvasLayer/DeathScreen/VBoxContainer/Turns.text = "Turns: %s" % turn_counter
	$CanvasLayer/DeathScreen.show()
	$AutoTurnTimer.start()


func _on_auto_turn_timer_timeout() -> void:
	process_turn()


func _on_paused() -> void:
	get_tree().paused = true
	Global.pause_count += 1


func _on_pause_button_pressed() -> void:
	%PauseMusic.play()
	get_tree().paused = true
	Global.pause_count += 1
	pause_screen.show()
	pause_button.hide()


func _on_unpaused() -> void:
	Global.pause_count = max(0, Global.pause_count - 1)
	if Global.pause_count <= 0:
		pause_screen.hide()
		%PauseMusic.stop()
		pause_button.show()
		get_tree().paused = false


func _on_new_run_button_pressed() -> void:
	requested_reload_current_mode.emit()


func _on_title_screen_button_pressed() -> void:
	_on_unpaused()
	requested_mode_switch.emit(ModeSwitcher.Modes.TITLE)


func _on_metamorphosis_tutorial_completed() -> void:
	Global.walls.set_cell(Vector2i(9, -15), -1)
	Global.walls.set_cell(Vector2i(10, -15), -1)


func _on_bogo_timer_timeout() -> void:
	if tutorial_level:
		return
	var bogo_sort = bogosort_scene.instantiate()
	if not is_instance_valid(bogo_egg):
		return
	else:
		bogo_sort.global_position = bogo_egg.global_position
		bogo_egg.queue_free()
	add_child(bogo_sort)
