extends Sprite2D


const CHAR_SEPARATOR_COLOR: Color = Color(0, 1.0, 0, 0.5)
const CHAR_BASE_COLOR: Color = Color(1.0, 0, 0, 0.5)
const LETTER_SELECTION_COLOR: Color = Color(1.0, 1.0, 1.0, 0.5)

const MIN_ZOOM_AMOUNT: int = 1
const MAX_ZOOM_AMOUNT: int = 20
var current_zoom_amount: int = 1

var is_texture_set: bool = false
var texture_dimensions: Vector2 = Vector2(0, 0)
var draw_from: Vector2 = Vector2(0, 0)
var base_offset = 0

var is_mouse_pressed: bool = false

var char_counts: Vector2 = Vector2(1, 1)
var letter_indices: Vector2 = Vector2(0, 0)
var char_dimensions: Vector2 = Vector2(1, 1)

var current_char_advance: int = 0


func set_current_letter(index: int) -> void:
	letter_indices.x = index % int(char_counts.x)
	letter_indices.y = floor(index / char_counts.x)
	
	#update()


func _input(event: InputEvent) -> void:
	_handle_image_controls(event)


func _handle_image_controls(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_MIDDLE:
					is_mouse_pressed = event.pressed
				MOUSE_BUTTON_WHEEL_UP:
					current_zoom_amount = min(current_zoom_amount + 1, MAX_ZOOM_AMOUNT)
					scale = Vector2.ONE * current_zoom_amount
				MOUSE_BUTTON_WHEEL_DOWN:
					current_zoom_amount = max(current_zoom_amount - 1, MIN_ZOOM_AMOUNT)
					scale = Vector2.ONE * current_zoom_amount
		if not event.pressed:
			match event.button_index:
				MOUSE_BUTTON_MIDDLE:
					is_mouse_pressed = event.pressed
	
	if event is InputEventMouseMotion and is_mouse_pressed:
		position += event.relative


func _draw() -> void:
	if not is_texture_set:
		return
		
	_draw_letter_selection()
	_draw_letter_separators()
	_draw_base_line()


func _draw_letter_selection():
	draw_rect(Rect2(
		draw_from.x + (char_dimensions.x * letter_indices.x),
		draw_from.y + (char_dimensions.y * letter_indices.y),
		current_char_advance,
		char_dimensions.y
	), LETTER_SELECTION_COLOR)


func _draw_base_line():
	for i in range(char_counts.y + 1):
		if i == char_counts.y + 1:
			return
		
		draw_line(
			Vector2(draw_from.x, draw_from.y + (char_dimensions.y * i) + base_offset),
			Vector2(
				draw_from.x + texture_dimensions.x,
				draw_from.y + (char_dimensions.y * i) + base_offset
			),
			CHAR_BASE_COLOR
		)


func _draw_letter_separators():
	for i in range(char_counts.x + 1):
		draw_line(
			Vector2(draw_from.x + (char_dimensions.x * i), draw_from.y),
			Vector2(draw_from.x + (char_dimensions.x * i), draw_from.y + texture_dimensions.y),
			CHAR_SEPARATOR_COLOR
		)
		
	for i in range(char_counts.y + 1):
		draw_line(
			Vector2(draw_from.x, draw_from.y + (char_dimensions.y * i)),
			Vector2(draw_from.x + texture_dimensions.x, draw_from.y + (char_dimensions.y * i)),
			CHAR_SEPARATOR_COLOR
		)


func set_current_char_advance(value: int) -> void:
	current_char_advance = value
	
	#update()


func set_wireframe(options: Dictionary) -> void:
	if not is_texture_set:
		return
		
	if options.has("char_width") and int(options["char_width"]) != char_dimensions.x:
		char_dimensions.x = options.char_width
		char_counts.x = get_horizontal_char_count()
		queue_redraw()
	
	if options.has("char_height") and int(options["char_height"]) != char_dimensions.y:
		char_dimensions.y = options.char_height
		char_counts.y = get_vertical_char_count()
		queue_redraw()
		
	if options.has("base_from_top") and int(options["base_from_top"]) != base_offset:
		base_offset = options.base_from_top
		queue_redraw()


func set_image(tex: Texture) -> void:
	texture = tex
	
	texture_dimensions = texture.get_size()
	
	draw_from.x = -(texture_dimensions.x / 2)
	draw_from.y = -(texture_dimensions.y / 2)
	
	char_counts.x = get_horizontal_char_count()
	char_counts.y = get_vertical_char_count()
	
	is_texture_set = true
	
	#update()


func set_char_width(value: int) -> void:
	char_dimensions.x = max(1, value)


func set_char_height(value: int) -> void:
	char_dimensions.y = max(1, value)


func get_horizontal_char_count() -> int:
	return int(texture_dimensions.x / char_dimensions.x)


func get_vertical_char_count() -> int:
	return int(texture_dimensions.y / char_dimensions.y)
