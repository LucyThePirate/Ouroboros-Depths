extends Node2D

var root_node: Branch
var tile_size: int = 100
@onready var floors: TileMapLayer = $Floors
@onready var walls = $Walls as TileMapLayer
@onready var objects = $Objects as TileMapLayer
@onready var path_tile := [3, Vector2i(1, 3)]
@onready var room_floor_tile := [3, Vector2i(0, 3)]
@onready var stone_wall_tile := [2, Vector2i(1, 0)]
@onready var stone_floor_tile := [2, Vector2i(0, 1)]
@onready var door_horizontal_tile := [2, Vector2i(1, 2)]
@onready var door_vertical_tile := [2, Vector2i(2, 2)]

var paths: Array = []


func _ready():
	root_node = Branch.new(Vector2i(0, 0), Vector2i(60, 30))
	root_node.split(4, paths)
	queue_redraw()
	pass


func _draw():
	var rng = RandomNumberGenerator.new()

	for leaf in root_node.get_leaves():
		var padding = Vector4i(
			rng.randi_range(0, 0),  # Left Padding
			rng.randi_range(0, 0),  # Up Padding
			rng.randi_range(1, 1),  # Right Padding
			rng.randi_range(1, 1)  # Down Padding
		)
		draw_rect(
			Rect2(
				leaf.position.x * tile_size,  # x
				leaf.position.y * tile_size,  # y
				leaf.size.x * tile_size,  # width
				leaf.size.y * tile_size  # height
			),
			Color.GREEN,  # colour
			false  # is filled
		)
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				var tile_coordinate = Vector2i(x + leaf.position.x, y + leaf.position.y)
				if not is_inside_padding(x, y, leaf, padding):
					floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
				else:  # Wall
					floors.set_cell(tile_coordinate, stone_floor_tile[0], stone_floor_tile[1])
					walls.set_cell(tile_coordinate, stone_wall_tile[0], stone_wall_tile[1])
					# here Vector2i(2, 2) is where our floor is in the tileset we are using
		for path in paths:
			draw_line(path["left"] * tile_size, path["right"] * tile_size, Color.RED, 10)
			if path["left"].y == path["right"].y:
				# horizontal
				for i in range(path["right"].x - path["left"].x):
					var tile_coordinate = Vector2i(path["left"].x + i, path["left"].y)
					floors.set_cell(tile_coordinate, path_tile[0], path_tile[1])
					if walls.get_cell_tile_data(tile_coordinate):
						floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
						walls.set_cell(tile_coordinate, -1)

						if (
							walls.get_cell_tile_data(tile_coordinate - Vector2i(0, 1))
							and walls.get_cell_tile_data(tile_coordinate + Vector2i(0, 1))
						):
							leaf.path_intersection_count += 1
							objects.set_cell(
								tile_coordinate, door_vertical_tile[0], door_vertical_tile[1]
							)
			else:
				# vertical
				for i in range(path["right"].y - path["left"].y):
					var tile_coordinate = Vector2i(path["left"].x, path["left"].y + i)
					floors.set_cell(tile_coordinate, 3, Vector2i(2, 1))
					if walls.get_cell_tile_data(tile_coordinate):
						floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
						walls.set_cell(tile_coordinate, -1)

						if (
							walls.get_cell_tile_data(tile_coordinate - Vector2i(1, 0))
							and walls.get_cell_tile_data(tile_coordinate + Vector2i(1, 0))
						):
							leaf.path_intersection_count += 1
							objects.set_cell(
								tile_coordinate, door_horizontal_tile[0], door_horizontal_tile[1]
							)
	for leaf in root_node.get_leaves():
		print("leaf path count:", leaf.path_intersection_count)
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				var tile_coordinate = Vector2i(x + leaf.position.x, y + leaf.position.y)
				if leaf.path_intersection_count != 1:
					floors.set_cell(tile_coordinate, stone_floor_tile[0], stone_floor_tile[1])


func is_inside_padding(x, y, leaf, padding):
	return (
		x <= padding.x
		or y <= padding.y
		or x >= leaf.size.x - padding.z
		or y >= leaf.size.y - padding.w
	)
