extends Node2D

@export var map : TileMap

@export var last_player_map_position : Vector2i

@export_flags_2d_physics var senses

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_player_brain_component_uncovered_fog(creature, radius : int = 3):
	if not map:
		return
	var location = creature.global_position
	var map_coordinates = map.local_to_map(location)
	if map_coordinates == last_player_map_position:
		return
	last_player_map_position = map_coordinates
	for x in range(0, (radius * 2) + 1):
		for y in range(0, (radius * 2) + 1):
			var c = map_coordinates + Vector2i(x - (radius), y - (radius))
			
			# Check if player has line-of-sight before uncovering fog
			if has_line_of_sight(map.map_to_local(c), creature):
				map.set_cell(-1, c, -1)


func has_line_of_sight(from : Vector2, creature : Creature) -> bool:
	# Check sight
	var space_state = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var query = PhysicsRayQueryParameters2D.create(from, Vector2(creature.global_position), senses, [self])
	var result = space_state.intersect_ray(query)
	if result and result.collider == creature:
		#print(result.collider.name)
		return true
	return false
