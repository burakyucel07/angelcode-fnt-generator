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
	"pages": [
		{
			"file": "",
		}
	],
	"chars": [],
	"kernings": [],
}

var char_data_keys = [
	"id", "x", "y", "width", "height",
	"xoffset", "yoffset", "xadvance", "page", "chnl",
]


func add_char(character, x, y, width, height, x_advance):
	var raw_code = str(character).to_wchar().hex_encode()
	var char_id = "0x" + raw_code.substr(2, 2) + raw_code.substr(0, 2)
	char_id = char_id.hex_to_int()
	
	file_structure.chars.push_back({
		"id": int(char_id),
		"x": int(x),
		"y": int(y),
		"width": int(min(width, x_advance)),
		"height": int(height),
		"xoffset": 0,
		"yoffset": 0,
		"xadvance": int(min(width, x_advance)),
		"page": 0,
		"chnl": 15,
	})


func add_values(values):
	file_structure.info.face = values.font_name
	file_structure.info.size = values.char_dimensions.y
	file_structure.common.lineHeight = values.char_dimensions.y
	file_structure.common.base = values.base_from_top
	file_structure.common.scaleW = values.texture_dimensions.x
	file_structure.common.scaleH = values.texture_dimensions.y
	file_structure.pages[0].file = values.texture_name + "." + values.file_extension
	
	var char_count: int =  values.char_list.length()
	var h_char_count: int = int(values.texture_dimensions.x) / int(values.char_dimensions.x)
	for i in range(char_count):
		add_char(values.char_list[i],
				(i % h_char_count) * values.char_dimensions.x,
				(i / h_char_count) * values.char_dimensions.y,
				values.char_dimensions.x, values.char_dimensions.y,
				values.advance_infos[i])


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
	
	var file = File.new()
	var err = file.open(directory + "/" + tex_name.split(".")[0] + ".fnt", File.WRITE)
	if err != OK:
		print(err)
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
	
	var file = File.new()
	var err = file.open(directory + "/" + tex_name.split(".")[0] + ".fnt", File.WRITE)
	if err != OK:
		print(err)
		return false

	file.store_string(fnt_data)
	file.close()
	
	return true


func _format_fnt_data_value(value):
	match typeof(value):
		TYPE_INT:
			return str(value)
		TYPE_REAL:
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
		TYPE_REAL:
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
