extends SkillStrategy

@export var spark_line_scene: PackedScene

var currently_executing := false
var radius = 2
var damage = 0


func _ready():
	super()


func on_stack_execution_started(grid_entity: GridEntity):
	currently_executing = true
	grid_entity.moved.connect(_on_grid_entity_moved.bind(grid_entity))


func on_skill_queued():
	damage += 1
	super()


func _on_grid_entity_moved(_old_coord: Vector2i, _new_coord: Vector2i, grid_entity: GridEntity):
	if not currently_executing:
		return
	var grid_coords = grid_entity.grid_coords
	var offset = -radius + 1
	for i in range(radius * 2 - 1):
		for j in range(radius * 2 - 1):
			var check_coords = grid_coords + Vector2i(offset + i, offset + j)
			if (
				Global.entity_positions.has(check_coords)
				and is_instance_valid(Global.entity_positions[check_coords])
			):
				var target = Global.entity_positions[check_coords]
				if target == grid_entity:
					continue
				grid_entity.hit(target, damage)
				var new_spark_line = spark_line_scene.instantiate() as Line2D
				new_spark_line.global_position = grid_entity.global_position
				new_spark_line.add_point(target.global_position - grid_entity.global_position)
				get_tree().current_scene.add_child(new_spark_line)


func on_stack_execution_finished(_grid_entity: GridEntity):
	currently_executing = false
	damage = 0


func use_skill(grid_entity: GridEntity):
	var grid_coords = grid_entity.grid_coords
	%SparkLineVFX.clear_points()
	var adjacent = [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 0)
	]
	for a in adjacent:
		var check_coords = grid_coords + a
		%SparkLineVFX.add_point(Global.floors.map_to_local(check_coords))
		if (
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
		):
			var target = Global.entity_positions[check_coords]
			grid_entity.hit(target, 1)
	%AnimationPlayer.play("ShowSparkLine_2")
	%ZapSFX.play()
	super(grid_entity)
