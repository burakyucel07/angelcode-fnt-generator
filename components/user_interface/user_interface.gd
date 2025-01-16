extends HBoxContainer


signal form_field_updated(new_values)
signal export_button_pressed()
signal export_as_xml_button_pressed()
signal selected_char_index_changed(new_index, char_advance)
signal file_selected(texture_info)

const MAX_CHAR_RESOLUTION: int = 256
const MIN_CHAR_RESOLUTION: int = 8
const MAX_ADVANCE_INFO_COUNT: int = 1025

var current_char_atlas: AtlasTexture = null
var texture_dimensions: Vector2 = Vector2(0, 0)
var char_counts: Vector2 = Vector2(1, 1)

var advance_infos: Array = []
var current_char_index: int = 0

var texture_file_extension: String = ""

@onready var open_file_dialog = %OpenFile

@onready var current_char_rect = %SelectedChar
@onready var current_char_advance = %CurrentAdvance
@onready var current_advance_edit = %CurrentAdvanceEdit
@onready var advance_limit_label = %AdvanceLimit
@onready var current_char_edit = %CurrentChar
@onready var char_count_label = %CharCount

@onready var font_name_edit = %FontNameEdit
@onready var texture_name_edit = %TextureNameEdit
@onready var char_width_edit = %CharWidthEdit
@onready var char_height_edit = %CharHeightEdit
@onready var base_value_edit = %BaseValue
@onready var char_list_edit = %CharListEdit

@onready var info_dialog = %InfoDialog
@onready var overwrite_dialog = %OverwriteConfirmation

@onready var advance_panel = %AdvancePanel
@onready var font_info_panel = %FontInfo


func _ready() -> void:
	_unlock_edit_buttons(false)
	
	current_char_atlas = AtlasTexture.new()
	
	for i in range(MAX_ADVANCE_INFO_COUNT):
		advance_infos.push_back(0)


func open_overwrite_confirm_dialog():
	overwrite_dialog.popup_centered()


func set_char_width(value: int) -> void:
	char_width_edit.text = str(value)
	_on_char_width_edit_focus_exited()


func set_char_height(value: int) -> void:
	char_height_edit.text = str(value)
	_on_char_height_edit_focus_exited()


func set_base_from_top(value: int) -> void:
	base_value_edit.text = str(value)
	_on_base_value_edit_focus_exited()


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
		var file_name_tokens = file_directory_tokens[file_directory_tokens.size() - 1].split(".")
		texture_file_extension = file_name_tokens[file_name_tokens.size() - 1]
		file_name_tokens.remove_at(file_name_tokens.size() - 1)
		for i in range(file_name_tokens.size()):
			texture_name_edit.text += file_name_tokens[i]
			font_name_edit.text += file_name_tokens[i]
			
		for i in range(file_directory_tokens.size() - 1):
			texture_info.texture_directory += file_directory_tokens[i]
			if i < file_directory_tokens.size() - 2:
				texture_info.texture_directory += "/"
			
		_unlock_edit_buttons(true)
		
		file_selected.emit(texture_info)
	else:
		open_dialog(tr("FILE_IS_NOT_TEXTURE"))


func _update_current_visible_char():
	current_char_atlas.region = Rect2(
		(int(current_char_index % int(char_counts.x))) * int(char_width_edit.text),
		(int(current_char_index / char_counts.x)) * int(char_height_edit.text),
		int(char_width_edit.text),
		int(char_height_edit.text)
	)
	
	var selected_index = min(current_char_index, advance_infos.size() - 1)
	
	current_advance_edit.text = str(advance_infos[selected_index])
	current_char_edit.text = str(selected_index)
	
	current_char_rect.custom_minimum_size.x = advance_infos[selected_index]
	current_char_rect.custom_minimum_size.y = advance_infos[selected_index]
	
	current_char_advance.custom_minimum_size.x = advance_infos[selected_index]
	current_char_advance.custom_minimum_size.y = advance_infos[selected_index]


func _on_image_load_button_pressed() -> void:
	open_file_dialog.popup_centered_ratio()


func _on_char_advance_edit_focus_exited() -> void:
	var char_advance = min(int(char_width_edit.text), int(current_advance_edit.text))
	char_advance = max(char_advance, 0)
	
	advance_infos[current_char_index] = char_advance
	
	_update_current_visible_char()
	
	form_field_updated.emit({
		"current_char_advance": advance_infos[current_char_index],
	})


func _on_current_char_edit_focus_exited() -> void:
	current_char_index = min((char_counts.x * char_counts.y) - 1, int(current_char_edit.text))
	current_char_index = max(current_char_index, 0)
	
	_update_current_visible_char()
	
	selected_char_index_changed.emit(current_char_index, advance_infos[current_char_index])


func _on_char_width_edit_focus_exited() -> void:
	var char_width = max(MIN_CHAR_RESOLUTION, int(char_width_edit.text))
	char_width = min(MAX_CHAR_RESOLUTION, char_width)
	char_width_edit.text = str(char_width)
	char_counts.x = max(1, int(texture_dimensions.x / char_width))
	_update_char_count()
	current_char_edit.text = str(min(
			int(current_char_edit.text), int(char_count_label.text)))
	
	for i in range(MAX_ADVANCE_INFO_COUNT):
		advance_infos[i] = min(char_width, advance_infos[i])
		
	advance_limit_label.text = str(char_width)
		
	_update_current_visible_char()
	
	form_field_updated.emit({
		"char_width": char_width,
	})


func _on_char_height_edit_focus_exited() -> void:
	var char_height = max(MIN_CHAR_RESOLUTION, int(char_height_edit.text))
	char_height = min(MAX_CHAR_RESOLUTION, char_height)
	char_height_edit.text = str(char_height)
	char_counts.y = max(1, int(texture_dimensions.y / char_height))
	_update_char_count()
	current_char_edit.text = str(min(
			int(current_char_edit.text), int(char_count_label.text)))
	
	_update_current_visible_char()
	
	form_field_updated.emit({
		"char_height": char_height,
	})


func _on_decrease_base_button_pressed() -> void:
	base_value_edit.text = str(max(0, int(base_value_edit.text) - 1))
	form_field_updated.emit({"base_from_top": int(base_value_edit.text)})


func _on_increase_base_button_pressed() -> void:
	base_value_edit.text = str(min(int(base_value_edit.text) + 1, int(char_height_edit.text)))
	form_field_updated.emit({"base_from_top": int(base_value_edit.text)})


func _on_increase_advance_button_pressed() -> void:
	advance_infos[current_char_index] = min(
			advance_infos[current_char_index] + 1,
			int(char_width_edit.text)
		)
		
	_update_current_visible_char()
	
	form_field_updated.emit({
		"current_char_advance": advance_infos[current_char_index],
	})


func _on_decrease_advance_button_pressed() -> void:
	advance_infos[current_char_index] = max(
			advance_infos[current_char_index] - 1,
			0
		)
	
	_update_current_visible_char()
	
	form_field_updated.emit({
		"current_char_advance": advance_infos[current_char_index],
	})


func _on_prev_char_button_pressed() -> void:
	set_current_char_index(current_char_index - 1)


func _on_next_char_button_pressed() -> void:
	set_current_char_index(current_char_index + 1)


## Set the selected character index
func set_current_char_index(index: int) -> void:
	current_char_index = clamp(index, 0, (char_counts.x * char_counts.y) - 1)
	selected_char_index_changed.emit(current_char_index, advance_infos[current_char_index])
	current_char_edit.text = str(current_char_index)
	_update_current_visible_char()


func _on_base_value_edit_focus_exited() -> void:
	var parsed_value = int(base_value_edit.text)
	parsed_value = max(0, parsed_value)
	parsed_value = min(int(char_height_edit.text), parsed_value)
	
	base_value_edit.text = str(parsed_value)
	
	form_field_updated.emit({"base_from_top": parsed_value})


func _get_export_values():
	return {
		"font_name": font_name_edit.text,
		"texture_name": texture_name_edit.text,
		"char_dimensions": Vector2(int(char_width_edit.text), int(char_height_edit.text)),
		"texture_dimensions": texture_dimensions,
		"base_from_top": int(base_value_edit.text),
		"char_list": char_list_edit.text,
		"advance_infos": advance_infos.slice(0, char_list_edit.text.length()),
		"file_extension": texture_file_extension,
	}


func _on_export_button_pressed() -> void:
	var export_values = _get_export_values()
	
	export_button_pressed.emit(export_values)


func _on_export_as_xml_button_pressed() -> void:
	var export_values = _get_export_values()
	
	export_as_xml_button_pressed.emit(export_values)
