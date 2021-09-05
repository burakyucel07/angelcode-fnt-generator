extends HBoxContainer


signal form_field_updated(new_values)
signal export_button_pressed()
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

onready var open_file_dialog = $"TextureInfoControl/OpenFile"

onready var current_char_rect = $"LetterControl/Items/Panel/Controls/Texture/Panel/Char"
onready var current_char_advance = $"LetterControl/Items/Panel/Controls/Texture/Panel/Advance"
onready var decrease_advance_button = $"LetterControl/Items/Panel/Controls/AdvanceControls/Centering/Items/Buttons/Decrease"
onready var increase_advance_button = $"LetterControl/Items/Panel/Controls/AdvanceControls/Centering/Items/Buttons/Increase"
onready var current_advance_edit = $"LetterControl/Items/Panel/Controls/AdvanceControls/Centering/Items/Edit/CurrentAdvance"
onready var advance_limit_label = $"LetterControl/Items/Panel/Controls/AdvanceControls/Centering/Items/Edit/AdvanceLimit"
onready var prev_char_button = $"LetterControl/Items/Panel/Controls/LetterSwitch/Centering/Controls/PrevChar"
onready var next_char_button = $"LetterControl/Items/Panel/Controls/LetterSwitch/Centering/Controls/NextChar"
onready var current_char_edit = $"LetterControl/Items/Panel/Controls/LetterSwitch/Centering/Controls/CurrentChar"
onready var char_count_label = $"LetterControl/Items/Panel/Controls/LetterSwitch/Centering/Controls/CharCount"

onready var image_load_button = $"TextureInfoControl/Panel/Margin/Scroll/Items/ImageLoad"
onready var font_name_edit = $"TextureInfoControl/Panel/Margin/Scroll/Items/FontNameEdit"
onready var texture_name_edit = $"TextureInfoControl/Panel/Margin/Scroll/Items/TextureNameEdit"
onready var char_width_edit = $"TextureInfoControl/Panel/Margin/Scroll/Items/CharacterDimensions/CharacterWidthEdit"
onready var char_height_edit = $"TextureInfoControl/Panel/Margin/Scroll/Items/CharacterDimensions/CharacterHeightEdit"
onready var decrease_base_button = $"TextureInfoControl/Panel/Margin/Scroll/Items/BaseSettings/DecreaseButton"
onready var increase_base_button = $"TextureInfoControl/Panel/Margin/Scroll/Items/BaseSettings/IncreaseButton"
onready var base_value_edit = $"TextureInfoControl/Panel/Margin/Scroll/Items/BaseSettings/BaseValue"
onready var char_list_edit = $"TextureInfoControl/Panel/Margin/Scroll/Items/CharacterListEdit"
onready var export_button = $"TextureInfoControl/Panel/Margin/Scroll/Items/ExportButton"

onready var info_dialog = $"InfoDialog"
onready var overwrite_dialog = $"FntOverwriteConfirmation"

func _ready() -> void:
	open_file_dialog.connect("file_selected", self, "_on_file_selected")
	
	image_load_button.connect("pressed", self, "_on_image_load_button_pressed")
	char_width_edit.connect("focus_exited", self, "_on_char_width_edit_focus_exited")
	char_height_edit.connect("focus_exited", self, "_on_char_height_edit_focus_exited")
	
	current_advance_edit.connect("focus_exited", self, "_on_char_advance_edit_focus_exited")
	current_char_edit.connect("focus_exited", self, "_on_current_char_edit_focus_exited")
	
	decrease_base_button.connect("pressed", self, "_on_decrease_base_button_pressed")
	increase_base_button.connect("pressed", self, "_on_increase_base_button_pressed")
	base_value_edit.connect("focus_exited", self, "_on_base_value_edit_focus_exited")
	export_button.connect("pressed", self, "_on_export_button_pressed")
	
	decrease_advance_button.connect("pressed", self, "_on_decrease_advance_button_pressed")
	increase_advance_button.connect("pressed", self, "_on_increase_advance_button_pressed")
	current_advance_edit.connect("text_changed", self, "_on_current_advance_edit_text_changed")
	prev_char_button.connect("pressed", self, "_on_prev_char_button_pressed")
	next_char_button.connect("pressed", self, "_on_next_char_button_pressed")
	current_char_edit.connect("text_changed", self, "_on_current_char_edit_text_changed")
	
	texture_name_edit.connect("focus_exited", self, "_on_texture_name_edit_focus_exited")
	
	_unlock_edit_buttons(false)
	
	texture_name_edit.editable = false
	
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
	char_width_edit.editable = value
	char_height_edit.editable = value
	decrease_base_button.disabled = !value
	increase_base_button.disabled = !value
	decrease_advance_button.disabled = !value
	increase_advance_button.disabled = !value
	base_value_edit.editable = value
	export_button.disabled = !value
	current_advance_edit.editable = value
	prev_char_button.disabled = !value
	next_char_button.disabled = !value
	current_char_edit.editable = value
	font_name_edit.editable = value
	char_list_edit.readonly = !value
	export_button.disabled = !value


func _on_file_selected(file_path: String) -> void:
	var image = Image.new()
	var tex = null
	var err = image.load(file_path)
	if err != OK:
		print(err)
	else:
		tex = ImageTexture.new()
		tex.create_from_image(image, 0)
	
	var texture_info = {
		"texture": null,
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
		file_name_tokens.remove(file_name_tokens.size() - 1)
		for i in range(file_name_tokens.size()):
			texture_name_edit.text += file_name_tokens[i]
			font_name_edit.text += file_name_tokens[i]
			
		for i in range(file_directory_tokens.size() - 1):
			texture_info.texture_directory += file_directory_tokens[i]
			if i < file_directory_tokens.size() - 2:
				texture_info.texture_directory += "/"
			
		_unlock_edit_buttons(true)
		
		emit_signal("file_selected", texture_info)
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
	
	current_char_rect.rect_min_size.x = advance_infos[selected_index]
	current_char_rect.rect_min_size.y = advance_infos[selected_index]
	
	current_char_advance.rect_min_size.x = advance_infos[selected_index]
	current_char_advance.rect_min_size.y = advance_infos[selected_index]


func _on_image_load_button_pressed() -> void:
	open_file_dialog.popup_centered_ratio()


func _on_char_advance_edit_focus_exited() -> void:
	var char_advance = min(int(char_width_edit.text), int(current_advance_edit.text))
	char_advance = max(char_advance, 0)
	
	advance_infos[current_char_index] = char_advance
	
	_update_current_visible_char()
	
	emit_signal("form_field_updated", {
		"current_char_advance": advance_infos[current_char_index],
	})


func _on_current_char_edit_focus_exited() -> void:
	current_char_index = min((char_counts.x * char_counts.y) - 1, int(current_char_edit.text))
	current_char_index = max(current_char_index, 0)
	
	_update_current_visible_char()
	
	emit_signal("selected_char_index_changed", current_char_index, advance_infos[current_char_index])


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
	
	emit_signal("form_field_updated", {
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
	
	emit_signal("form_field_updated", {
		"char_height": char_height,
	})


func _on_decrease_base_button_pressed() -> void:
	base_value_edit.text = str(max(0, int(base_value_edit.text) - 1))
	emit_signal("form_field_updated", {"base_from_top": int(base_value_edit.text)})


func _on_increase_base_button_pressed() -> void:
	base_value_edit.text = str(min(int(base_value_edit.text) + 1, int(char_height_edit.text)))
	emit_signal("form_field_updated", {"base_from_top": int(base_value_edit.text)})


func _on_increase_advance_button_pressed() -> void:
	advance_infos[current_char_index] = min(
			advance_infos[current_char_index] + 1,
			int(char_width_edit.text)
		)
		
	_update_current_visible_char()
	
	emit_signal("form_field_updated", {
		"current_char_advance": advance_infos[current_char_index],
	})


func _on_decrease_advance_button_pressed() -> void:
	advance_infos[current_char_index] = max(
			advance_infos[current_char_index] - 1,
			0
		)
	
	_update_current_visible_char()
	
	emit_signal("form_field_updated", {
		"current_char_advance": advance_infos[current_char_index],
	})


func _on_prev_char_button_pressed() -> void:
	current_char_index = max(0, current_char_index - 1)
	current_char_index = min((char_counts.x * char_counts.y) - 1, current_char_index)
	emit_signal("selected_char_index_changed", current_char_index, advance_infos[current_char_index])
	
	current_char_edit.text = str(current_char_index)
	
	_update_current_visible_char()


func _on_next_char_button_pressed() -> void:
	current_char_index = min((char_counts.x * char_counts.y) - 1, current_char_index + 1)
	emit_signal("selected_char_index_changed", current_char_index, advance_infos[current_char_index])
	
	current_char_edit.text = str(current_char_index)
	
	_update_current_visible_char()


func _on_base_value_edit_focus_exited() -> void:
	var parsed_value = int(base_value_edit.text)
	parsed_value = max(0, parsed_value)
	parsed_value = min(int(char_height_edit.text), parsed_value)
	
	base_value_edit.text = str(parsed_value)
	
	emit_signal("form_field_updated", {"base_from_top": parsed_value})


func _on_export_button_pressed() -> void:
	var export_values = {
		"font_name": font_name_edit.text,
		"texture_name": texture_name_edit.text,
		"char_dimensions": Vector2(int(char_width_edit.text), int(char_height_edit.text)),
		"texture_dimensions": texture_dimensions,
		"base_from_top": int(base_value_edit.text),
		"char_list": char_list_edit.text,
		"advance_infos": advance_infos.slice(0, char_list_edit.text.length()),
		"file_extension": texture_file_extension,
	}
	
	emit_signal("export_button_pressed", export_values)
