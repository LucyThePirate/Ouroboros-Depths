@tool
extends GameMode

@export var boulder_splash: PackedScene
@export var spawn_smoke_scene: PackedScene
@export var player_scene: PackedScene
@export var creature_scene: Array[PackedScene]
var creatures_spawnable_on_this_floor: Array[PackedScene]
@export var challenge_rating_capacity := 15.0
var current_challenge_rating := 0.0
@export var entity_spawn_limit := 5
var current_entity_count := 0
@export var bogosort_scene: PackedScene
var bogo_egg_scene = preload("uid://dvtenp8g812ei")
var bogo_egg: BraindeadAI

@export var levels: Array[PackedScene]
var spawnable_ground: Array

@onready var pause_screen := %PauseScreen
@onready var pause_button := %PauseButton

#region Fog
@onready var fog = %Fog
@onready var shade = %Shade as TileMapLayer

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
@onready var shade_tile := [3, Vector2i(1, 1)]
@onready var fog_tile := [2, Vector2i(9, 8)]
#endregion

var turn_counter = 0
var current_floor := 0
var current_level: DungeonLevel
var player
var angry_at_player = 0


func _ready():
	if Engine.is_editor_hint():
		%Fog.hide()
		%Shade.hide()
		return
	current_level = levels[min(current_floor, levels.size() - 1)].instantiate()
	add_child(current_level)
	%Fog.show()
	%Shade.show()
	_on_unpaused()
	if current_level.tutorial_level:
		Global.metamorphosis_completed.connect(_on_metamorphosis_tutorial_completed)
	if not Global.UI_closed.is_connected(_on_unpaused):
		Global.UI_closed.connect(_on_unpaused)
		Global.UI_opened.connect(_on_paused)
		Global.aggroed_towards_player.connect(add_to_angry_at_player_list)
		Global.deaggroed_towards_player.connect(remove_from_angry_at_player_list)
	Global.entity_positions = {}
	Global.metamorphosis_reroll_cost = 3
	$CanvasLayer/DeathScreen.hide()
#region Setting up RNG and dungeon generation
	if not current_level.generator:
		# There already is a level, no need to generate
		Global.floors = current_level.floors
		Global.walls = current_level.walls
		if Global.floors.get_used_cells().size() > 0:
			var valid_stair_locations = []
			for tile in Global.floors.get_used_cells():
				var wall_data = Global.walls.get_cell_tile_data(tile)
				if not wall_data or not wall_data.get_custom_data("is_solid"):
					valid_stair_locations.append(tile)
			if (
				not Global.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])
				and not valid_stair_locations.is_empty()
			):
				# No stair tiles, generate our own
				var stairs_up_location = valid_stair_locations.pick_random()
				valid_stair_locations.erase(stairs_up_location)
				Global.floors.set_cell(stairs_up_location, stairs_up_tile[0], stairs_up_tile[1])
			if (
				not Global.floors.get_used_cells_by_id(stairs_down_tile[0], stairs_down_tile[1])
				and not valid_stair_locations.is_empty()
			):
				var stairs_down_location = valid_stair_locations.pick_random()
				Global.floors.set_cell(
					stairs_down_location, stairs_down_tile[0], stairs_down_tile[1]
				)
				valid_stair_locations.erase(stairs_down_location)
		_initialize_fog()
		if get_tree().get_nodes_in_group("Player"):
			player = get_tree().get_nodes_in_group("Player")[0]
			player.grid_entity.warp(
				Global.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0]
			)
		else:
			if (
				Global.floors.get_used_cells().size() > 0
				and Global.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])
			):
				player = (
					spawn_entity(
						Global.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0],
						player_scene
					)
					as Player
				)
		initialize_monster_spawns()
		_initialize_entities()
		return
	# Else, no existing level, generate
	current_level.generator.initialize(current_floor, floors, walls, fog)
	current_level.generator.generate_level()
	for extra_node in current_level.generator.extra_nodes:
		extra_node.reparent(self)
		if extra_node is CreatureAI:
			extra_node.grid_entity.global_position = extra_node.global_position - Vector2(50, 50)

	if not player:
		player = (
			spawn_entity(
				current_level.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0],
				player_scene,
				false
			)
			as Player
		)
	player.grid_entity.warp(
		Global.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0]
	)
	Global.entity_positions[Global.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0]] = (
		player.grid_entity
	)

	spawn_bogo_egg()

	initialize_monster_spawns()
	_initialize_fog()
	_initialize_entities()


func _initialize_fog():
	shade.clear()
	if current_level.lighting_mode == current_level.LightingModes.FULLY_LIT:
		return
	for tile in Global.floors.get_used_cells():
		fog.set_cell(tile, fog_tile[0], fog_tile[1])

	#fog.set_pattern(walls.get_used_rect().position, walls.get_pattern(walls.get_used_cells()))

	Global.fog = fog
	Global.shade = shade
	_update_fog(Vector2i.ZERO, Vector2i.ZERO, true)


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
	current_floor += 1
	if current_level.tutorial_level:
		requested_mode_switch.emit(ModeSwitcher.Modes.TITLE)
		return
	%FloorLabel.text = "Floor: %s" % current_floor
	%AnimationPlayer.play("floor_text_fade_in")
	await get_tree().create_timer(1).timeout

	Global.next_floor_reached.emit()
	for entity in get_tree().get_nodes_in_group("GridEntity") as Array[GridEntity]:
		if not entity.is_in_group("Player"):
			entity.on_death(true)
	angry_at_player = 0
	current_challenge_rating = 0.0
	current_entity_count = 0
	Global.floors.clear()
	Global.walls.clear()
	spawnable_ground.clear()
	creatures_spawnable_on_this_floor.clear()
	fog.clear()
	current_level.queue_free()
	_ready()
	player.next_floor_reached()
	%AnimationPlayer.play("floor_text_fade_out")


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
	if new_entity.is_in_group("Player"):
		player.grid_entity.moved.connect(_update_fog)
		player.health_component.max_health_updated.connect(_player_max_health_updated)
		player.turn_component.turn_ended.connect(process_turn)
		player.grid_entity.died.connect(_on_player_died)
		player.descended.connect(_redraw_map)
	new_entity.initialize()


func _player_max_health_updated():
	if player:
		_update_fog(Vector2i.ZERO, player.grid_entity.grid_coords)
		var max_health_percentage = player.health_component.get_max_health_percentage()
		%Shade.self_modulate.a = (.36 + (1.0 - max_health_percentage) / 1.5)
		%BackgroundTint.color = Color(
			max_health_percentage, max_health_percentage, max_health_percentage
		)


func _update_fog(
	_old_coords := Vector2i.ZERO, new_coords := Vector2i.ZERO, initializing_fog := false
):
	if current_level.lighting_mode == current_level.LightingModes.FULLY_LIT:
		return
	if initializing_fog:
		if Global.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1]).size() > 0:
			new_coords = (
				Global.floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0]
			)

	var light_radius = 7
	if player:
		light_radius = ceili(
			float(light_radius) * player.health_component.get_max_health_percentage()
		)

	if current_level.lighting_mode != current_level.LightingModes.FOG_ONLY:
		for tile in Global.visible_tiles.keys():
			Global.shade.set_cell(tile, shade_tile[0], shade_tile[1])

	Global.visible_tiles = {}
	Light.computeFov(new_coords, light_radius)

	for tile in Global.visible_tiles.keys():
		Global.shade.set_cell(tile, -1)
		fog.set_cell(tile, -1)


func spawn_entity(grid_coordinate: Vector2i, entity_scene: PackedScene, call_deferred := false):
	var new_entity = entity_scene.instantiate()
	new_entity.global_position = floors.map_to_local(grid_coordinate)
	if call_deferred:
		call_deferred("add_child", new_entity)
	else:
		add_child(new_entity)
	return new_entity


func process_turn():
	if not Global.is_turn_based():
		turn_counter += 1
		if current_level.continually_spawn_creatures and (turn_counter % 10) == 0:
			try_spawning_random_monster(true)
		return

	turn_counter += 1
	if current_level.continually_spawn_creatures and (turn_counter % 10) == 0:
		try_spawning_random_monster(true)
	#print(turn_counter)
	for turn_component in get_tree().get_nodes_in_group("TurnComponent"):
		if turn_component:
			turn_component.take_turn()
	Global.turn_passed.emit()


func spawn_monster_at_coords(grid_coordinate: Vector2i):
	var new_entity = spawn_entity(grid_coordinate, creature_scene.pick_random())
	current_challenge_rating += new_entity.grid_entity.challenge_rating


func initialize_monster_spawns():
	for creature in creature_scene:
		var new_entity = creature.instantiate()
		add_child(new_entity)
		if (
			not current_level.is_arena
			and new_entity.grid_entity.challenge_rating > current_floor + 1
		):
			new_entity.queue_free()
			continue
		creatures_spawnable_on_this_floor.append(creature)
		new_entity.queue_free()

	for tile in Global.floors.get_used_cells():
		var wall_data = Global.walls.get_cell_tile_data(tile)
		if not wall_data or not wall_data.get_custom_data("is_solid"):
			spawnable_ground.append(tile)
	for random_monster_tile in walls.get_used_cells_by_id(
		Tiles.random_monster_tile[0], Tiles.random_monster_tile[1]
	):
		walls.set_cell(random_monster_tile, -1)
		spawn_monster_at_coords(random_monster_tile)
	if current_level.initial_spawn_creatures:
		for i in range(int(10 + current_floor) / 2):
			try_spawning_random_monster(false)


func try_spawning_random_monster(initialize_entity := true):
	if current_entity_count < entity_spawn_limit + current_floor:
		if spawnable_ground.is_empty():
			return
		var grid_coordinate = spawnable_ground.pick_random()
		if not _is_obstructed(grid_coordinate):
			var new_entity = (
				spawn_entity(grid_coordinate, creatures_spawnable_on_this_floor.pick_random())
				as CreatureAI
			)
			current_challenge_rating += new_entity.grid_entity.challenge_rating
			current_entity_count += 1
			if initialize_entity:
				_initialize_entity(new_entity.grid_entity)
				if current_level.is_arena:
					new_entity._update_angry_at(player.grid_entity)
				if current_level.is_arena or not Global.shade.get_cell_tile_data(grid_coordinate):
					var new_smoke = spawn_smoke_scene.instantiate()
					new_smoke.global_position = Global.floors.map_to_local(grid_coordinate)
					add_child(new_smoke)


func spawn_bogo_egg():
	if current_level.tutorial_level:
		return
	var grid_coordinate = (
		Global.floors.get_used_cells_by_id(bogo_tile[0], bogo_tile[1], 1).pick_random()
	)
	bogo_egg = spawn_entity(grid_coordinate, bogo_egg_scene)
	bogo_egg.egg_died.connect(_on_bogo_timer_timeout)
	bogo_egg.egg_timer_expired.connect(_on_bogo_timer_timeout)


func _open_door(door_coords):
	walls.set_cell(door_coords, -1)


func _push_tile(tile_coords, direction):
	if Global.entity_positions.has(tile_coords + direction):
		return
	Tiles.move_wall(tile_coords, tile_coords + direction)


func spawn_tile(tile_coords, tile_data := [-1, Vector2i(-1, -1)]):
	var existing_tile = Global.floors.get_cell_tile_data(tile_coords)
	if existing_tile and existing_tile.get_custom_data("indestructable"):
		return
	#Global.floors.set_cell(tile_coords, 2, Vector2i(0, 1))
	if not existing_tile:
		Global.floors.set_cell(tile_coords, Tiles.Floors["dirt"][0], Tiles.Floors["dirt"][1])
	else:
		Global.floors.set_cell(tile_coords, tile_data[0], tile_data[1])


func spawn_wall(tile_coords, tile_data := [-1, Vector2i(-1, -1)]):
	var existing_wall = Global.walls.get_cell_tile_data(tile_coords)
	var existing_tile = Global.floors.get_cell_tile_data(tile_coords)
	if existing_wall and existing_wall.get_custom_data("indestructable"):
		return
	if not existing_tile:
		Global.floors.set_cell(tile_coords, Tiles.Floors["dirt"][0], Tiles.Floors["dirt"][1])
	elif (
		existing_tile.get_custom_data("is_liquid")
		and not existing_tile.get_custom_data("indestructable")
	):
		Global.floors.set_cell(tile_coords, Tiles.Floors["dirt"][0], Tiles.Floors["dirt"][1])
		var splashVFX = boulder_splash.instantiate()
		Global.walls.add_child(splashVFX)
		splashVFX.global_position = Global.floors.map_to_local(tile_coords)
	else:
		Global.walls.set_cell(tile_coords, tile_data[0], tile_data[1])


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
			if current_level.is_arena or not Global.shade.get_cell_tile_data(summon_coords):
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
	if current_level.is_arena or current_level.tutorial_level:
		return
	if not is_despawning and grid_entity.challenge_rating > 0:
		current_entity_count -= 1
		var stairs_down_location = Global.floors.get_used_cells_by_id(
			stairs_down_tile[0], stairs_down_tile[1]
		)
		if not stairs_down_location.is_empty():
			Global.walls.set_cell(stairs_down_location[0], -1)


func _on_player_died(_despawning) -> void:
	if not current_level.is_arena:
		for tile in Global.floors.get_used_cells():
			Global.shade.set_cell(tile, -1)
	fog.hide()
	shade.hide()
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
	if current_level.tutorial_level:
		return
	var bogo_sort = bogosort_scene.instantiate()
	if not is_instance_valid(bogo_egg):
		return
	else:
		bogo_sort.global_position = bogo_egg.global_position
		bogo_egg.queue_free()
	add_child(bogo_sort)
