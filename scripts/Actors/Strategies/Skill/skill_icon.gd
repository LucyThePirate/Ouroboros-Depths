extends PanelContainer

class_name SkillIcon

signal clicked
signal left_clicked
signal right_clicked

@onready var reload_texture = %TextureRect.texture

@export var border_default_texture = preload("uid://73gcb7ha8dq4")
@export var border_cursor_texture = preload("uid://bxkca84uofc70")
@export var border_directional_texture = preload("uid://kbypq2vn6bka")

enum IconPositions { HAND, BAG, STACK, METAMORPHOSIS }
var icon_position := IconPositions.HAND


func set_skill(new_skill: SkillStrategy, new_position := IconPositions.HAND):
	icon_position = new_position
	if not new_skill:
		set_icon_texture(null)
		set_text("Reload")
		set_stack_size(0)
		update_border(null)
	else:
		set_icon_texture(new_skill.icon.texture)
		set_stack_size(new_skill.stack_size)
		set_count(new_skill.count)
		set_text(new_skill.skill_name)
		update_border(new_skill)
	match new_position:
		IconPositions.HAND:
			%CountLabel.hide()
			%NameLabel.show()
			%StackSizeLabel.show()
		IconPositions.STACK:
			%CountLabel.hide()
			%NameLabel.hide()
			%StackSizeLabel.show()
		IconPositions.BAG:
			%CountLabel.show()
			%NameLabel.show()
			%StackSizeLabel.hide()
		IconPositions.METAMORPHOSIS:
			%CountLabel.hide()
			%NameLabel.show()
			%StackSizeLabel.hide()


func update_border(skill: SkillStrategy):
	if not skill:
		%BorderTexture.texture = null
		return
	match skill.skill_type:
		SkillStrategy.SkillTypes.DEFAULT:
			%BorderTexture.texture = border_default_texture
		SkillStrategy.SkillTypes.CURSOR:
			%BorderTexture.texture = border_cursor_texture
		SkillStrategy.SkillTypes.DIRECTIONAL:
			%BorderTexture.texture = border_directional_texture
		_:
			%BorderTexture.texture = null
	match skill.rarity:
		SkillStrategy.SkillRarities.CURSE:
			%BorderTexture.self_modulate = Color.BLACK
		SkillStrategy.SkillRarities.COMMON:
			%BorderTexture.self_modulate = Color.LIME
		SkillStrategy.SkillRarities.RARE:
			%BorderTexture.self_modulate = Color.PURPLE
		SkillStrategy.SkillRarities.RAINBOW:
			%BorderTexture.self_modulate = Color.YELLOW


func set_icon_texture(new_icon: Texture2D):
	if not new_icon:
		%TextureRect.texture = reload_texture
		%StackSizeLabel.hide()
	else:
		%TextureRect.texture = new_icon


func set_stack_size(new_size := 0):
	if new_size == 0:
		%StackSizeLabel.text = ""
	else:
		%StackSizeLabel.text = "%s" % new_size
	if icon_position == IconPositions.STACK:
		pass
		#custom_minimum_size.x = 100 + (50 * (new_size - 1))
		#if new_size > 0:
		#custom_minimum_size.x = 100 + (50 * (new_size - 1))
		#else:
		#custom_minimum_size.x = 100


func set_count(new_count := 1):
	if new_count == 1:
		%CountLabel.hide()
		%CountLabel.text = ""
	else:
		%CountLabel.show()
		%CountLabel.text = "x%s" % new_count


func set_text(new_text := ""):
	%NameLabel.text = new_text


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		clicked.emit()
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			left_clicked.emit()
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit()
