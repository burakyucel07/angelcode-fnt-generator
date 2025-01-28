extends TextureRect


const CHAR_SEPARATOR_COLOR: Color = Color(0, 1.0, 0, 0.5)
const CHAR_BASE_COLOR: Color = Color(1.0, 0, 0, 0.5)
const CHAR_OFFSET_POS_COLOR: Color = Color(0, 1.0, 1.0, 0.5)
const CHAR_OFFSET_NEG_COLOR: Color = Color(1.0, 1.0, 0, 0.5)
const LETTER_BOX_COLOR := Color(1.0, 1.0, 1.0, 0.25)
const LETTER_SELECTION_COLOR := Color(1.0, 1.0, 1.0, 0.5)

const MIN_ZOOM_AMOUNT: int = 1
const MAX_ZOOM_AMOUNT: int = 20

@export var user_interface: UserInterface

var current_zoom_amount: int = 1

var is_texture_set: bool = false

var is_mouse_pressed: bool = false

var letter_indices := Vector2i(0, 0)

@onready var camera = $"../MainCamera"


func set_current_letter(index: int) -> void:
	var chars_x: int = user_interface.char_counts.x
	letter_indices.x = index % chars_x
	letter_indices.y = index / chars_x
	
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
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
		camera.position -= event.relative


func _draw() -> void:
	if not is_texture_set:
		return
		
	_draw_letter_selection()
	_draw_letter_separators()
	_draw_base_line()


func _gui_input(event: InputEvent) -> void:
	var char_dimensions = user_interface.char_dimensions
	var char_counts = user_interface.char_counts
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			letter_indices.x = event.position.x / char_dimensions.x
			letter_indices.y = event.position.y / char_dimensions.y
			user_interface.set_current_char_index(letter_indices.y * char_counts.x + letter_indices.x)
			queue_redraw()


func _draw_letter_selection():
	var char_dimensions = user_interface.char_dimensions
	var char_counts = user_interface.char_counts
	var char_offsets = user_interface.char_offsets
	for j in range(char_counts.y):
		for i in range(char_counts.x):
			var index = i + j * char_counts.x
			var color = LETTER_BOX_COLOR
			if letter_indices == Vector2i(i, j):
				color = LETTER_SELECTION_COLOR
			var top_left := Vector2i(
				char_dimensions.x * i,
				char_dimensions.y * j
			)
			var selection_size := Vector2i(
				user_interface.advance_infos[index],
				char_dimensions.y
			)
			var offset: Vector2i = user_interface.char_offsets[index]
			draw_rect(
				Rect2(
					top_left - offset,
					selection_size
				),
				color
			)
			if offset.x != 0:
				var line_color = CHAR_OFFSET_POS_COLOR
				if offset.x > 0:
					offset.x -= char_dimensions.x
					line_color = CHAR_OFFSET_NEG_COLOR
				var line_start := top_left - Vector2i(offset.x, 0)
				draw_line(line_start, line_start + Vector2i(0, char_dimensions.y), line_color)
			if offset.y != 0:
				var line_color = CHAR_OFFSET_POS_COLOR
				if offset.y > 0:
					offset.y -= char_dimensions.y
					line_color = CHAR_OFFSET_NEG_COLOR
				var line_start := top_left - Vector2i(0, offset.y)
				draw_line(line_start, line_start + Vector2i(char_dimensions.x, 0), line_color)


func _draw_base_line():
	var char_counts = user_interface.char_counts
	var char_dimensions = user_interface.char_dimensions
	var texture_dimensions = user_interface.texture_dimensions
	var base_from_top = user_interface.base_from_top
	for i in range(char_counts.y):
		if i == char_counts.y + 1:
			return
		
		draw_line(
			Vector2(0, (char_dimensions.y * i) + base_from_top),
			Vector2(
				texture_dimensions.x,
				(char_dimensions.y * i) + base_from_top
			),
			CHAR_BASE_COLOR,
		)


func _draw_letter_separators():
	var char_counts = user_interface.char_counts
	var char_dimensions = user_interface.char_dimensions
	var texture_dimensions = user_interface.texture_dimensions
	for i in range(char_counts.x + 1):
		draw_line(
			Vector2((char_dimensions.x * i), 0),
			Vector2((char_dimensions.x * i), texture_dimensions.y),
			CHAR_SEPARATOR_COLOR
		)
		
	for i in range(char_counts.y + 1):
		draw_line(
			Vector2(0, char_dimensions.y * i),
			Vector2(texture_dimensions.x, char_dimensions.y * i),
			CHAR_SEPARATOR_COLOR
		)


func update_wireframe() -> void:
	if not is_texture_set:
		return

	queue_redraw()


func set_image(tex: Texture) -> void:
	texture = tex
	
	pivot_offset = user_interface.texture_dimensions / 2
	
	is_texture_set = true
	
	# TODO: Is this required? Unsure what this is meant to do.
	#queue_redraw()
