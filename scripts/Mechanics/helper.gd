extends Node

var slowdown_enabled: bool = true
var reload_count: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().grab_focus()
	toggle_slowdown()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("DebugExit"):
		print_rich("[rainbow][wave]DEBUG: Debugging sesh complete![/wave][/rainbow]")
		get_tree().quit()
	if Input.is_action_just_pressed("DebugReloadScene"):
		print_rich("[color=LIME]DEBUG: Reloaded (", reload_count, ")")
		reload_count += 1
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("DebugToggleSlowdown"):
		toggle_slowdown()


func toggle_slowdown():
	slowdown_enabled = not slowdown_enabled
	if slowdown_enabled:
		print_rich("DEBUG: Slowdown turned on.")
	else:
		print_rich("[shake]DEBUG: Slowdown turned off![/shake]")


func align_to_grid(position: Vector2) -> Vector2:
	var newPosition = Vector2(round(position.x), round(position.y))
	return newPosition


# Credit goes to: tknockaert from https://forum.godotengine.org/t/is-there-a-way-to-get-any-offspring-that-belongs-in-a-certain-group-directly/14265/4
static func find_children_in_group(parent: Node, group: String, recursive: bool = false):
	var output: Array[Node] = []
	for child in parent.get_children():
		if child.is_in_group(group):
			output.append(child)
	if recursive:
		for child in parent.get_children():
			var recursive_output = find_children_in_group(child, group, recursive)
			for recursive_child in recursive_output:
				output.append(recursive_child)
	return output
