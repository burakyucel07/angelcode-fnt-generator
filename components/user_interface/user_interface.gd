class_name UserInterface
extends HBoxContainer


signal form_field_updated()
signal export_button_pressed(new_values: Dictionary)
signal export_as_xml_button_pressed()
signal selected_char_index_changed(new_index: int)
signal file_selected(texture_info: Dictionary)

const MAX_CHAR_RESOLUTION: int = 256
const MIN_CHAR_RESOLUTION: int = 8
const MAX_ADVANCE_INFO_COUNT: int = 1025

var current_char_atlas: AtlasTexture = null
var texture_dimensions := Vector2i.ZERO
var char_counts := Vector2i.ONE

var advance_infos: PackedInt32Array = []
var char_offsets: Array[Vector2i] = []
var current_char_index: int = 0

var base_from_top := 0

var texture_file_extension: String = ""

@onready var open_file_dialog = %OpenFile

@onready var current_char_rect = %SelectedChar
@onready var current_char_advance = %CurrentAdvance
@onready var current_advance_edit = %CurrentAdvanceEdit
@onready var char_dimensions_edit = %CharDimensionsEdit
@onready var current_offset_edit = %CurrentOffsetEdit
@onready var advance_limit_label = %AdvanceLimit
@onready var current_char_edit = %CurrentChar
@onready var char_count_label = %CharCount

@onready var font_name_edit = %FontNameEdit
@onready var texture_name_edit = %TextureNameEdit
@onready var base_edit = %BaseEdit
@onready var char_list_edit = %CharListEdit

@onready var info_dialog = %InfoDialog
@onready var overwrite_dialog = %OverwriteConfirmation

@onready var advance_panel = %AdvancePanel
@onready var font_info_panel = %FontInfo


func _ready() -> void:
	_unlock_edit_buttons(false)
	
	current_char_atlas = AtlasTexture.new()
	
	advance_infos.resize(MAX_ADVANCE_INFO_COUNT)
	char_offsets.resize(MAX_ADVANCE_INFO_COUNT)
	char_offsets.fill(Vector2i.ZERO)


func open_overwrite_confirm_dialog():
	overwrite_dialog.popup_centered()


func set_char_dimensions(value: Vector2i) -> void:
	char_dimensions_edit.value = value


func get_char_dimensions() -> Vector2i:
	return char_dimensions_edit.value


func set_current_char(value: int) -> void:
	current_char_edit.text = str(value)
	_on_current_char_edit_focus_exited()


func _update_char_count():
	char_count_label.text = str((char_counts.x * char_counts.y) - 1)


func open_dialog(message: String) -> void:
	info_dialog.dialog_text = message
	info_dialog.popup_centered()


func _unlock_edit_buttons(value: bool) -> void:
	advance_panel.visible = value
	font_info_panel.visible = value


func _on_file_selected(file_path: String) -> void:
	if file_path.ends_with(".fnt"):
		var file = FNTFile.new()
		_import_values(file_path.get_base_dir(), file.import_from_text(file_path))
		return
	_load_texture(file_path)


func _load_texture(file_path: String) -> void:
	var image = Image.load_from_file(file_path)
	var tex = ImageTexture.create_from_image(image)
	
	var texture_info = {
		"tex": null,
		"is_texture_loaded": false,
		"texture_path": file_path,
		"texture_directory": "",
	}
	
	if tex is Texture:
		texture_info.tex = tex
		texture_info.is_texture_loaded = true
		
		texture_dimensions = tex.get_size()
		current_char_rect.texture = current_char_atlas
		current_char_atlas.atlas = tex
		_update_current_visible_char()
		
		texture_name_edit.text = ""
		var file_directory_tokens = file_path.split("/")
		var file_name_tokens = file_directory_tokens[-1].split(".")
		texture_file_extension = file_name_tokens[-1]
		file_name_tokens.remove_at(file_name_tokens.size() - 1)
		for i in file_name_tokens.size():
			texture_name_edit.text += file_name_tokens[i]
			if font_name_edit.text.is_empty():
				font_name_edit.text += file_name_tokens[i]
			
		for i in file_directory_tokens.size() - 1:
			texture_info.texture_directory += file_directory_tokens[i]
			if i < file_directory_tokens.size() - 2:
				texture_info.texture_directory += "/"
			
		_unlock_edit_buttons(true)
		
		file_selected.emit(texture_info)
	else:
		open_dialog(tr("FILE_IS_NOT_TEXTURE"))


func _update_current_visible_char():
	var pos = Vector2i(current_char_index % char_counts.x, current_char_index / char_counts.x)
	var char_dimensions = get_char_dimensions()
	current_char_atlas.region = Rect2(
		pos * char_dimensions,
		char_dimensions,
	)
	
	var selected_index = min(current_char_index, advance_infos.size() - 1)
	
	current_offset_edit.value = char_offsets[selected_index]
	current_advance_edit.text = str(advance_infos[selected_index])
	current_char_edit.text = str(selected_index)
	
	current_char_rect.offset_left = char_offsets[selected_index].x
	current_char_rect.offset_right = char_offsets[selected_index].x
	current_char_rect.offset_top = char_offsets[selected_index].y
	current_char_rect.offset_bottom = char_offsets[selected_index].y
	
	current_char_rect.custom_minimum_size.x = advance_infos[selected_index]
	current_char_rect.custom_minimum_size.y = advance_infos[selected_index]
	
	current_char_advance.custom_minimum_size.x = advance_infos[selected_index]
	current_char_advance.custom_minimum_size.y = advance_infos[selected_index]


func _on_image_load_pressed() -> void:
	open_file_dialog.filters = ["*.png,*.jpg,*.jpeg;Image Files;image/png,image/jpeg"]
	open_file_dialog.popup_centered_ratio()


func _on_font_load_pressed() -> void:
	open_file_dialog.filters = ["*.fnt;FNT Files;application/font"]
	open_file_dialog.popup_centered_ratio()


func _on_char_advance_edit_focus_exited() -> void:
	var char_advance = min(get_char_dimensions().x, int(current_advance_edit.text))
	char_advance = max(char_advance, 0)
	
	advance_infos[current_char_index] = char_advance
	
	_update_current_visible_char()
	
	form_field_updated.emit()


func _on_current_char_edit_focus_exited() -> void:
	current_char_index = min((char_counts.x * char_counts.y) - 1, int(current_char_edit.text))
	current_char_index = max(current_char_index, 0)
	
	_update_current_visible_char()
	
	selected_char_index_changed.emit(current_char_index)


func _on_increase_advance_button_pressed() -> void:
	advance_infos[current_char_index] = min(
			advance_infos[current_char_index] + 1,
			get_char_dimensions().x
		)
		
	_update_current_visible_char()
	
	form_field_updated.emit()


func _on_decrease_advance_button_pressed() -> void:
	advance_infos[current_char_index] = max(
			advance_infos[current_char_index] - 1,
			0
		)
	
	_update_current_visible_char()
	
	form_field_updated.emit()


func _on_prev_char_button_pressed() -> void:
	set_current_char_index(current_char_index - 1)


func _on_next_char_button_pressed() -> void:
	set_current_char_index(current_char_index + 1)


## Set the selected character index
func set_current_char_index(index: int) -> void:
	current_char_index = clamp(index, 0, (char_counts.x * char_counts.y) - 1)
	selected_char_index_changed.emit(current_char_index)
	current_char_edit.text = str(current_char_index)
	_update_current_visible_char()


func _on_base_edit_value_changed(value: float) -> void:
	base_from_top = value
	
	form_field_updated.emit()


func _import_values(directory: String, values: Dictionary) -> void:
	font_name_edit.text = values.info.face
	var chars := ""
	advance_infos.clear()
	advance_infos.resize(MAX_ADVANCE_INFO_COUNT)
	char_offsets.resize(MAX_ADVANCE_INFO_COUNT)
	char_offsets.fill(Vector2i.ZERO)
	var dimensions = Vector2i.ZERO
	for i in values.chars.size():
		var char = values.chars[i]
		chars += String.chr(char.id)
		char_offsets[i] = Vector2i(char.xoffset, char.yoffset)
		advance_infos[i] = char.xadvance
		dimensions = Vector2i(char.width, char.height).max(dimensions)
	var texture_path: String = values.pages[0].file
	base_edit.value = values.common.base
	texture_dimensions = Vector2(values.common.scaleW, values.common.scaleH)
	char_counts = texture_dimensions / dimensions
	set_char_dimensions(dimensions)
	char_list_edit.text = chars
	_load_texture(directory.path_join(texture_path))


func _get_export_values() -> Dictionary:
	return {
		"font_name": font_name_edit.text,
		"texture_name": texture_name_edit.text,
		"char_dimensions": get_char_dimensions(),
		"texture_dimensions": texture_dimensions,
		"base_from_top": base_edit.value,
		"char_list": char_list_edit.text,
		"char_offsets": char_offsets.slice(0, char_list_edit.text.length()),
		"advance_infos": advance_infos.slice(0, char_list_edit.text.length()),
		"file_extension": texture_file_extension,
	}


func _on_export_button_pressed() -> void:
	var export_values: Dictionary = _get_export_values()
	
	export_button_pressed.emit(export_values)


func _on_export_as_xml_button_pressed() -> void:
	var export_values = _get_export_values()
	
	export_as_xml_button_pressed.emit(export_values)


func _on_current_offset_edit_value_changed(value: Vector2i) -> void:
	char_offsets[current_char_index] = value
	
	_update_current_visible_char()
	
	form_field_updated.emit()


func _on_char_dimensions_edit_value_changed(value: Vector2i) -> void:
	char_counts = texture_dimensions / value
	_update_char_count()
	current_char_edit.text = str(min(
			int(current_char_edit.text), int(char_count_label.text)))
	
	for i in advance_infos.size():
		advance_infos[i] = min(value.x, advance_infos[i])
	
	advance_limit_label.text = str(value.x)
	
	_update_current_visible_char()
	
	form_field_updated.emit()
