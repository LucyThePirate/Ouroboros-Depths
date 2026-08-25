@abstract class_name SkillStrategy extends PanelContainer

signal moved_self
signal requested_direction_input(requester)
signal requested_cursor_input
signal direction_set
signal cursor_set
signal skill_finished
signal gained_status(status)

const SKILL_DESCRIPTION = preload("uid://bvsqgo23yrgum")

enum SkillRarities { CURSE, COMMON, RARE, RAINBOW }
enum SkillTypes { DEFAULT, DIRECTIONAL, CURSOR, NULL }
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
	JUDO_THROW,
	HARPOON,
	SUMMON_WASP,
	BOMB,
	FUSE,
	SPARK,
	CHOMP,
	DISGUISE,
	DIVIDE_N_CONQUER,
	SHIFT,
}

@export_category("Base Stats")
@export var skill_ID := SkillIDs.NONE
@export var count := 3
@onready var current_count := count
@export var is_depletable := false
@export var cost := 1
@export var rarity := SkillRarities.COMMON
@export var skill_type := SkillTypes.DEFAULT
@export var stack_size := 1

@export_category("AI Use Hints")
@export var max_per_stack := 100
@onready var current_in_stack := 0
@export var priority := 0
enum SkillUsageTypes { WHENEVER, COMBAT_ONLY, OUTSIDE_COMBAT_ONLY }
@export var when_to_use_skill := SkillUsageTypes.COMBAT_ONLY
@export var usable_on_walls := false

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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.hide()
	progress_bar.hide()


func ready_skill(grid_entity: GridEntity) -> bool:
	skill_crit = false
	use_skill(grid_entity)
	return true


func use_skill(_grid_entity: GridEntity):
	current_in_stack = 0
	skill_finished.emit()
	#if is_depletable and current_count > 0:
	#current_count -= 1


func can_use_skill() -> bool:
	return true


func on_next_floor_reached():
	current_count = count


func on_skill_drawn(_grid_entity: GridEntity):
	pass


func on_stack_execution_started(_grid_entity: GridEntity):
	pass


func on_stack_execution_finished(_grid_entity: GridEntity):
	pass


func request_direction():
	state = States.AWAITING_DIRECTION


func set_direction(newDirection: Vector2i):
	direction = newDirection
	state = States.IDLE


func request_cursor():
	state = States.AWAITING_CURSOR


func move_cursor(moveDirection: Vector2i, _grid_entity: GridEntity):
	cursor += moveDirection


func set_cursor_position(new_position: Vector2i, _grid_entity: GridEntity):
	cursor = new_position


func accept_cursor():
	state = States.IDLE
	$Cursor.hide()


func on_skill_queued():
	current_in_stack += 1

	if is_depletable and current_count > 0:
		current_count -= 1


func on_grid_entity_moved(old_coords: Vector2i, new_coords: Vector2i):
	pass


func on_entity_summoned(grid_entity: GridEntity, summoned_entity: CreatureAI):
	summoned_entity.set_team(grid_entity)


func display_skill_info() -> void:
	var new_skill_description = SKILL_DESCRIPTION.instantiate() as SkillDescription
	get_tree().current_scene.add_child(new_skill_description)
	new_skill_description.icon.texture = icon.texture
	new_skill_description.skill_name.text = skill_name
	new_skill_description.stack_size = stack_size
	new_skill_description.skill_desc.text = ""
	if is_depletable:
		new_skill_description.skill_desc.text += "[color=YELLOW]Depletable[/color]\n"
	new_skill_description.skill_desc.text += skill_desc
