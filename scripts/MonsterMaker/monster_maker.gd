extends Node2D

@export var canvas_dimensions : Vector2 = Vector2(100, 100)
@export var brush_size : int = 3 #setget change_brush_size
var _current_color : Color
@export_category("Camera Settings")
@export var zoom_speed : float = 10
@export var min_zoom : float = 0.2
@export var max_zoom : float = 2


var Canvas : Image = Image.create(canvas_dimensions.x, canvas_dimensions.y, true, Image.FORMAT_RGBA8)
var _texture_changed : bool = false
var _using_mouse : bool = true
var _cursor_on_canvas : bool = false
var drawing_line_queue = []
@onready var zoom = %Camera2D.zoom
@onready var cursor_base_scale = $Cursor.scale

@onready var save_dialog = $SaveDialog

func _ready():
	save_dialog.file_selected.connect(save_file_selected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _using_mouse:
		$Cursor.global_position = get_global_mouse_position()
	_handle_camera_controls(delta)
	#_slop()
	_update_texture()
	
func _draw():
	for line in drawing_line_queue:
		print(line)
		draw_line(line[0], line[1], line[2], 4.0)
	drawing_line_queue = []

func _input(event):
	if not _cursor_on_canvas:
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		if Input.is_action_pressed("DrawLeft"):
			_paint_pixel($Cursor.global_position, _current_color, brush_size)
			#drawing_line_queue.append([$Cursor.global_position, $Cursor.global_position - event.relative, Color.DARK_RED])
		if Input.is_action_pressed("DrawRight"):
			_paint_pixel($Cursor.global_position, Color(0, 0, 0, 0), brush_size)

func _handle_camera_controls(delta):
	# Handle zooming in/out
	if Input.is_action_pressed("DrawZoomIn"):
		_zoom_tween(zoom + (Vector2(zoom_speed,zoom_speed) * delta))
	if Input.is_action_pressed("DrawZoomOut"):
		_zoom_tween(zoom - (Vector2(zoom_speed,zoom_speed) * delta))

		
func _zoom_tween(zoom_amount):
	var tween = get_tree().create_tween()
	zoom_amount = zoom_amount.clamp(Vector2(min_zoom,min_zoom), Vector2(max_zoom, max_zoom))
	tween.tween_property(self, "zoom", zoom_amount, 0.75)
	%Camera2D.zoom = zoom
	print("Zoom: ", zoom)

func _paint_pixel(coordinates : Vector2, color : Color, size : int = 1):
	var scaled_coordinates = coordinates / %Canvas.scale
	scaled_coordinates = Vector2i(clampi(scaled_coordinates.x, 0, canvas_dimensions.x - 1), clampi(scaled_coordinates.y, 0, canvas_dimensions.y - 1))
	for x in range(0, size):
		for y in range(0, size):
			Canvas.set_pixelv(scaled_coordinates + Vector2i(x - (size / 2), y - (size / 2)), color)
	_texture_changed = true

func _update_texture():
	if (_texture_changed):
		_texture_changed = false
		$Canvas.texture = ImageTexture.create_from_image(Canvas)
		queue_redraw()

func _slop():
	Canvas.set_pixel(randi_range(0, 99), randi_range(0, 99), Color(0, randf_range(0.5, 1), 0))
	_texture_changed = true


func _on_brush_size_small_pressed():
	set_brush_size(1)


func _on_brush_size_medium_pressed():
	set_brush_size(2)


func _on_brush_size_large_pressed():
	set_brush_size(brush_size + 1)


func set_brush_size(new_size : int):
	brush_size = new_size
	$Cursor.scale = cursor_base_scale + cursor_base_scale * (.5 * (new_size - 1))

func _on_canvas_hitbox_mouse_entered():
	_cursor_on_canvas = true


func _on_canvas_hitbox_mouse_exited():
	_cursor_on_canvas = false


func _on_save_button_pressed():
	save_dialog.popup_centered()

func save_file_selected(path):
	# Wait until the frame has finished before getting the texture.
	await RenderingServer.frame_post_draw

	# Crop the image so we only have canvas area.
	var cropped_image = Canvas.get_region(Rect2($Canvas.position, canvas_dimensions))

	# Save the image with the passed in path we got from the save dialog.
	cropped_image.save_png(path)


func _on_color_picker_button_color_changed(color):
	_current_color = color
