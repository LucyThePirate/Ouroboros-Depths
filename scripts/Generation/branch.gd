extends Node

class_name Branch

# From tutorial: https://jonoshields.com/post/bsp-dungeon

var left_child: Branch  # yes, these are self referential :D
var right_child: Branch
var position: Vector2i
var size: Vector2i
var is_ending_branch := false
var split_iteration := -1
var path_intersection_count := 0


func _init(position, size):
	self.position = position
	self.size = size


func get_leaves():
	if not (left_child && right_child):
		self.is_ending_branch = true
		return [self]
	else:
		self.is_ending_branch = false
		return left_child.get_leaves() + right_child.get_leaves()


func split(remaining, paths):
	self.split_iteration = remaining
	var rng = RandomNumberGenerator.new()
	var split_percent = rng.randf_range(0.3, 0.7)  # splits will be between 30% and 70%
	var split_horizontal = size.y >= size.x  # if it is taller than it is wide

	if split_horizontal:
		# horizontal
		var left_height = int(size.y * split_percent)
		left_child = Branch.new(position, Vector2i(size.x, left_height))
		right_child = Branch.new(
			Vector2i(position.x, position.y + left_height), Vector2i(size.x, size.y - left_height)
		)
	else:
		# vertical
		var left_width = int(size.x * split_percent)
		left_child = Branch.new(position, Vector2i(left_width, size.y))
		right_child = Branch.new(
			Vector2i(position.x + left_width, position.y), Vector2i(size.x - left_width, size.y)
		)

	if remaining > 0:
		paths.push_back({"left": left_child.get_center(), "right": right_child.get_center()})
		left_child.split(remaining - 1, paths)
		right_child.split(remaining - 1, paths)


func get_center():
	return Vector2i(position.x + size.x / 2, position.y + size.y / 2)
