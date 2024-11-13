@tool
extends Node2D


@export var attack_height : float = 3
@export var preview_line_cuts : int = 15
@export var targetNode : Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_preview_on(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_attack_preview()


func _set_preview_on(preview_on : bool):
	$PreviewLine.visible = preview_on
	if preview_on:
		$Sprite.visible = true
	_update_attack_preview()


func _update_attack_preview():
	if not targetNode:
		return
	$Target.global_position = Debug.align_to_grid(targetNode.get_node("CreatureComponent").global_position)
	var mid_point = (global_position + $Target.global_position) / 2
	$Line2D.points[1] = mid_point - Vector2(0, attack_height)
	$Line2D.points[2] = $Target.global_position
	$PreviewLine.clear_points()
	for cut in range(preview_line_cuts):
		var line_progress = cut / float(preview_line_cuts)
		var q0 = $Line2D.points[0].lerp($Line2D.points[1], line_progress)
		var q1 = $Line2D.points[1].lerp($Line2D.points[2], line_progress)
		var r = q0.lerp(q1, line_progress)
		$PreviewLine.add_point(r)
