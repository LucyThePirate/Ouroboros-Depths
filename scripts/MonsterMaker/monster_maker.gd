extends Node2D

@export var canvas_dimensions : Vector2 = Vector2(100, 100)

var Canvas : Image = Image.create(canvas_dimensions.x, canvas_dimensions.y, true, Image.FORMAT_RGBA8)
var _texture_changed : bool = false
var _using_mouse : bool = true

var drawing_line_queue = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if _using_mouse:
		$Cursor.global_position = get_global_mouse_position()
	#_slop()
	_update_texture()
	
func _draw():
	for line in drawing_line_queue:
		print(line)
		draw_line(line[0], line[1], line[2], 4.0)
	drawing_line_queue = []

func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("draw_left"):
			_paint_pixel($Cursor.global_position, Color(0, randf_range(0.5, 1), 0))
			drawing_line_queue.append([$Cursor.global_position, $Cursor.global_position - event.relative, Color.DARK_RED])
		if Input.is_action_pressed("draw_right"):
			_paint_pixel($Cursor.global_position, Color(0, 0, 0, 0))

func _paint_pixel(coordinates : Vector2, color : Color):
	var scaled_coordinates = coordinates / %Canvas.scale
	scaled_coordinates = Vector2(clampi(scaled_coordinates.x, 0, canvas_dimensions.x - 1), clampi(scaled_coordinates.y, 0, canvas_dimensions.y - 1))
	Canvas.set_pixelv(scaled_coordinates, color)
	_texture_changed = true

func _update_texture():
	if (_texture_changed):
		_texture_changed = false
		$Canvas.texture = ImageTexture.create_from_image(Canvas)
		queue_redraw()

func _slop():
	Canvas.set_pixel(randi_range(0, 99), randi_range(0, 99), Color(0, randf_range(0.5, 1), 0))
	_texture_changed = true
