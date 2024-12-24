extends Node2D


enum ExportType {
	TEXT,
	XML,
}

@onready var font_image = $FontImage
@onready var user_interface = %UserInterface

var export_directory = ""
var export_file = ""
var fnt_file = null
var current_export_type = ExportType.TEXT

func _ready():
	user_interface.overwrite_dialog.get_ok_button().pressed.connect(_on_overwrite_confirm_pressed)


func _on_overwrite_confirm_pressed():
	_export()


func _export():
	var export_result: bool = false
	
	if current_export_type == ExportType.TEXT:
		export_result = fnt_file.export_as_text_to(export_directory, export_file)
	elif current_export_type == ExportType.XML:
		export_result = fnt_file.export_as_xml_to(export_directory, export_file)
	
	if export_result:
		user_interface.open_dialog(tr("FILE_EXPORT_SUCCESS"))
	else:
		user_interface.open_dialog(tr("FILE_EXPORT_ERROR"))


func _prepare_for_export(export_values, export_type):
	fnt_file = FNTFile.new()
	fnt_file.add_values(export_values)
	
	current_export_type = export_type
	
	export_file = export_values.texture_name + "." + export_values.file_extension
	var do_file_exist: bool = FileAccess.file_exists(
			export_directory + "/" + export_values.texture_name + ".fnt")
	
	if do_file_exist:
		user_interface.open_overwrite_confirm_dialog()
	else:
		_export()


func _on_file_selected(tex_info: Dictionary) -> void:
	font_image.set_image(tex_info.tex)
	
	var texture_size = tex_info.tex.get_size()
	
	export_directory = tex_info.texture_directory
	
	user_interface.set_char_width(texture_size.x / 2)
	user_interface.set_char_height(texture_size.y / 2)
	
	font_image.set_wireframe({
		"char_width": texture_size.x / 2,
		"char_height": texture_size.y / 2,
	})


func _on_form_field_updated(new_values):
	if new_values.has("current_char_advance"):
		font_image.set_current_char_advance(new_values.current_char_advance)
		
	font_image.set_wireframe(new_values)


func _on_selected_char_index_changed(new_index, char_advance):
	font_image.set_current_letter(new_index)
	font_image.set_current_char_advance(char_advance)


func _on_export_button_pressed(export_values):
	_prepare_for_export(export_values, ExportType.TEXT)


func _on_export_as_xml_button_pressed(export_values):
	_prepare_for_export(export_values, ExportType.XML)
