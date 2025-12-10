@abstract class_name SkillStrategy extends PanelContainer

signal moved_self
signal requested_direction_input(requester)
signal requested_cursor_input
signal direction_set
signal cursor_set
signal skill_finished
signal gained_status(status)

const SKILL_DESCRIPTION = preload("uid://bvsqgo23yrgum")

@export_category("Base Stats")
@export var count := 3
@onready var current_count := count
@export var is_depletable := false
@export var cost := 1

@export_category("AI Use Hints")
@export var max_per_stack := 3
@onready var current_in_stack := 0
@export var cooldown_turns := 1
@onready var current_cooldown := 0
@export var priority := 0

@export_category("Lore")
@export var skill_name: String
@export_multiline var skill_desc: String

@onready var icon = $Icon
@onready var progress_bar = $ProgressBar

var skill_crit := false
var show_UI = true

var direction: Vector2i
var cursor: Vector2i

enum States { IDLE, AWAITING_DIRECTION, AWAITING_CURSOR, PLAYING_ANIMATION }
var state = States.IDLE

enum SkillIDs {
	NONE,
	DASH,
	DEFEND,
	STOMP,
	FORTUNE_COOKIE,
	ORCHESTRATE,
	BE_PATIENT,
	DARK_STAR,
	LEAP,
	WARP,
	POSSIBILITIES,
	DRILL,
	EARTH_SPIKE,
}
@export var skill_ID := SkillIDs.NONE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.hide()
	progress_bar.hide()


func ready_skill(grid_entity: GridEntity) -> bool:
	skill_crit = false
	use_skill(grid_entity)
	return true


func use_skill(grid_entity: GridEntity):
	current_cooldown = 0
	#current_cooldown = cooldown_turns
	current_in_stack = 0
	skill_finished.emit()
	#if is_depletable and current_count > 0:
	#current_count -= 1


func can_use_skill() -> bool:
	#if current_cooldown > 0 or current_in_stack >= max_per_stack:
	#return false
	return true


func on_next_floor_reached():
	current_count = count


func on_stack_execution_started(grid_entity: GridEntity):
	pass


func on_stack_execution_finished(grid_entity: GridEntity):
	pass


func request_direction():
	state = States.AWAITING_DIRECTION


func set_direction(newDirection: Vector2i):
	direction = newDirection
	state = States.IDLE
	$Arrows.hide()


func request_cursor():
	state = States.AWAITING_CURSOR


func move_cursor(moveDirection: Vector2i, grid_entity: GridEntity):
	cursor += moveDirection


func set_cursor(newCursor: Vector2i):
	cursor = newCursor
	state = States.IDLE
	$Cursor.hide()


func decrement_turn_cooldown():
	current_cooldown = maxi(0, current_cooldown - 1)


func on_skill_queued():
	if is_depletable and current_count > 0:
		current_count -= 1


func on_grid_entity_moved(old_coords: Vector2i, new_coords: Vector2i):
	pass


func increment_in_stack_counter() -> bool:
	if current_in_stack >= max_per_stack:
		return false
	else:
		current_in_stack += 1
		return true


func display_skill_info() -> void:
	var new_skill_description = SKILL_DESCRIPTION.instantiate() as SkillDescription
	get_tree().current_scene.add_child(new_skill_description)
	new_skill_description.icon.texture = icon.texture
	new_skill_description.skill_name.text = skill_name
	new_skill_description.skill_desc.text = ""
	if is_depletable:
		new_skill_description.skill_desc.text += "[color=YELLOW]Depletable[/color]\n"
	new_skill_description.skill_desc.text += skill_desc
