class_name FNTFile
extends Node


var file_structure = {
	"info": {
		"face": "",
		"size": 0,
		"bold": 0,
		"italic": 0,
		"charset": "",
		"unicode": 1,
		"stretchH": 100,
		"smooth": 0,
		"aa": 1,
		"padding": [0, 0, 0, 0],
		"spacing": [0, 0],
		"outline": 0,
	},
	"common": {
		"lineHeight": 0,
		"base": 0,
		"scaleW": 0,
		"scaleH": 0,
		"pages": 1,
		"packed": 0,
		"alphaChnl": 0,
		"redChnl": 0,
		"greenChnl": 0,
		"blueChnl": 0,
	},
	"pages": [],
	"chars": [],
	"kernings": [],
}

var char_data_keys = [
	"id", "x", "y", "width", "height",
	"xoffset", "yoffset", "xadvance", "page", "chnl",
]


func add_char(character: String, pos: Vector2i, size: Vector2i, offset: Vector2i, x_advance: int):
	var char_id = character.unicode_at(0)
	
	file_structure.chars.push_back({
		"id": int(char_id),
		"x": pos.x,
		"y": pos.y,
		"width": size.x,
		"height": size.y,
		"xoffset": offset.x,
		"yoffset": offset.y,
		"xadvance": x_advance,
		"page": 0,
		"chnl": 15,
	})


func add_values(values: Dictionary) -> void:
	file_structure.info.face = values.font_name
	file_structure.info.size = values.char_dimensions.y
	file_structure.common.lineHeight = values.char_dimensions.y
	file_structure.common.base = values.base_from_top
	file_structure.common.scaleW = values.texture_dimensions.x
	file_structure.common.scaleH = values.texture_dimensions.y
	file_structure.pages = [{"file": values.texture_name + "." + values.file_extension}]
	
	var char_count: int = values.char_list.length()
	var h_char_count: int = int(values.texture_dimensions.x) / int(values.char_dimensions.x)
	for i in range(char_count):
		add_char(values.char_list[i],
				Vector2i(
					(i % h_char_count) * values.char_dimensions.x,
					(i / h_char_count) * values.char_dimensions.y
				),
				values.char_dimensions,
				values.char_offsets[i],
				values.advance_infos[i])


## Import font data from a .fnt file
func import_from_text(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print(FileAccess.get_open_error())
		return {}

	# RegEx for getting the tag name and contents
	var tag_regex = RegEx.create_from_string("^(\\w+)(.*)")
	# RegEx for getting field names and values
	var field_regex = RegEx.create_from_string("(\\w+)=(\"?[^\" ]*)")

	var line = file.get_line()
	while not file.eof_reached():
		var array_mode := false
		var tag = tag_regex.search(line).strings
		var tag_name = tag[1]

		# Skip array count tags (tags ending with "s" are plural, therefore arrays)
		if not tag_name.ends_with("s"):
			# If there's an array for this tag, switch to array mode
			if file_structure.has(tag[1] + "s"):
				tag_name += "s"
				file_structure[tag_name].append({})
				array_mode = true

			# Iterate through the fields in the tag
			for field in field_regex.search_all(tag[2]):
				var dict = file_structure[tag_name]
				if array_mode:
					dict = dict[-1]

				var val = field.strings[2]
				# If value begins with a quote mark, interpret as a string
				if val.begins_with("\""):
					val = val.substr(1) as String
				else:
					val = val as int
				dict[field.strings[1]] = val
		line = file.get_line()

	file.close()
	return file_structure


func export_as_text_to(directory, tex_name) -> bool:
	var fnt_data = "info "
	
	var info_data_keys = file_structure.info.keys()
	var info_data_values = file_structure.info.values()
	
	for i in range(info_data_keys.size()):
		fnt_data += info_data_keys[i] + "=" + _format_fnt_data_value(info_data_values[i])
		if i < info_data_keys.size() - 1:
			fnt_data += " "
		else:
			fnt_data += "\n"
	
	fnt_data += "common "
	
	var common_data_keys = file_structure.common.keys()
	var common_data_values = file_structure.common.values()
	
	for i in range(common_data_keys.size()):
		fnt_data += common_data_keys[i] + "=" + _format_fnt_data_value(common_data_values[i])
		if i < common_data_keys.size() - 1:
			fnt_data += " "
		else:
			fnt_data += "\n"
	
	var char_size = file_structure.chars.size()
	
	fnt_data += "page id=0 file=\"" + file_structure.pages[0].file + "\"\n"
	fnt_data += "chars count=" + str(char_size) + "\n"
	
	for i in range(char_size):
		fnt_data += "char "
		
		var char_data_values = file_structure.chars[i].values()
		
		for j in range(char_data_keys.size()):
			fnt_data += char_data_keys[j] + "=" + _format_fnt_data_value(char_data_values[j])
			if j < char_data_keys.size() - 1:
				fnt_data += " "
			else:
				fnt_data += "\n"
	
	fnt_data += "kernings count=" + str(file_structure.kernings.size()) + "\n"
	
	var file = FileAccess.open(directory + "/" + tex_name.split(".")[0] + ".fnt", FileAccess.WRITE)
	if file == null:
		print(FileAccess.get_open_error())
		return false

	file.store_string(fnt_data)
	file.close()
	
	return true


func export_as_xml_to(directory, tex_name) -> bool:
	var fnt_data = '<?xml version="1.0"?>\n'
	fnt_data += '<font>\n'
	
	var info_data_keys = file_structure.info.keys()
	var info_data_values = file_structure.info.values()
	
	fnt_data += '  <info '
	
	for i in range(info_data_keys.size()):
		fnt_data += info_data_keys[i] + '="' + _format_fnt_data_value_as_xml(info_data_values[i]) + '" ' 
	
	fnt_data += '/>\n'
	
	fnt_data += '  <common '
	
	var common_data_keys = file_structure.common.keys()
	var common_data_values = file_structure.common.values()
	
	for i in range(common_data_keys.size()):
		fnt_data += common_data_keys[i] + '="' + _format_fnt_data_value_as_xml(common_data_values[i]) + '" '
	
	fnt_data += '/>\n'
	
	fnt_data += '  <pages>\n'
	fnt_data += '    <page id="0" file="' + file_structure.pages[0].file + '" />\n'
	fnt_data += '  </pages>\n'
	
	var char_size = file_structure.chars.size()
	
	fnt_data += '  <chars count="' + str(char_size) + '">\n'
	
	for i in range(char_size):
		fnt_data += "    <char "
		
		var char_data_values = file_structure.chars[i].values()
		
		for j in range(char_data_keys.size()):
			fnt_data += char_data_keys[j] + '="' + _format_fnt_data_value_as_xml(char_data_values[j]) + '" '
		
		fnt_data += '/>\n'
	
	fnt_data += '  </chars>\n'
	
	var kerning_size = file_structure.kernings.size()
	fnt_data += '  <kernings count="' + str(kerning_size) + '">\n'
	fnt_data += '  </kernings>\n'
	
	fnt_data += '</font>\n'
	
	var file = FileAccess.open(directory + "/" + tex_name.split(".")[0] + ".fnt", FileAccess.WRITE)
	if file == null:
		print(FileAccess.get_open_error())
		return false

	file.store_string(fnt_data)
	file.close()
	
	return true


func _format_fnt_data_value(value):
	match typeof(value):
		TYPE_INT:
			return str(value)
		TYPE_FLOAT:
			return str(value)
		TYPE_STRING:
			return "\"" + str(value) + "\""
		TYPE_ARRAY:
			var formatted_array_value = ""
			for i in range(value.size()):
				formatted_array_value += str(value[i])
				if i < value.size() - 1:
					formatted_array_value += ","
					
			return formatted_array_value


func _format_fnt_data_value_as_xml(value):
	match typeof(value):
		TYPE_INT:
			return str(value)
		TYPE_FLOAT:
			return str(value)
		TYPE_STRING:
			return str(value)
		TYPE_ARRAY:
			var formatted_array_value = ""
			for i in range(value.size()):
				formatted_array_value += str(value[i])
				if i < value.size() - 1:
					formatted_array_value += ","
					
			return formatted_array_value
