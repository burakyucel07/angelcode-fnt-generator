extends Node2D


onready var font_image = get_node("FontImage")
onready var user_interface = get_node("Controls/UserInterface")

var export_directory = ""
var export_file = ""
var fnt_file = null

func _ready():
	user_interface.connect("file_selected", self, "_on_file_selected")
	user_interface.connect("form_field_updated", self, "_on_form_field_updated")
	user_interface.connect("selected_char_index_changed", self, "_on_selected_char_index_changed")
	user_interface.connect("export_button_pressed", self, "_on_export_button_pressed")
	user_interface.overwrite_dialog.get_ok().connect("pressed", self, "_on_overwrite_confirm_pressed")


func _on_overwrite_confirm_pressed():
	_export()


func _export():
	if fnt_file.export_to(export_directory, export_file):
		user_interface.open_dialog(tr("FILE_EXPORT_SUCCESS"))
	else:
		user_interface.open_dialog(tr("FILE_EXPORT_ERROR"))


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
	fnt_file = load("res://components/fnt_file.gd").new()
	fnt_file.add_values(export_values)
	
	var file_to_export: File = File.new()
	export_file = export_values.texture_name + "." + export_values.file_extension
	var do_file_exist: bool = file_to_export.file_exists(
			export_directory + "/" + export_values.texture_name + ".fnt")
	
	if do_file_exist:
		user_interface.open_overwrite_confirm_dialog()
	else:
		_export()
