@tool
class_name DossierBlankEffect extends RichTextEffect

signal blank_found(value: String, position: Vector2)

var bbcode: String = "blank"
var parsing_blanks: bool = false:
	set = set_parsing_blanks

var _current_blank_index: int = -1
var _current_blank_value: String = ""
var _current_blank_position: Vector2 = Vector2(-1.0, -1.0)


func _process_custom_fx(char_data: CharFXTransform) -> bool:
	if parsing_blanks:
		_process_blank(char_data)
	
	return true


func _process_blank(char_data: CharFXTransform) -> void:
	# The outline flag is set only for shadow and outline passes, but not the color pass.
	# We use this fact to make sure the processing is only done once per line.
	if not parsing_blanks || char_data.outline:
		return
	
	# Rich text effects don't contain the data for the entire affected string. So we
	# improvise using the relative index, which is available.
	#
	# If the incoming index is set to zero, flush the collected blank and notify the
	# owner label about it.
	if char_data.relative_index == 0 && not _current_blank_index == -1:
		_notify_blank_found()
	
	# Collect the blank. Store the starting data if we're at the beginning of it.
	if char_data.relative_index == 0:
		_current_blank_index = char_data.range.x
		_current_blank_value = char_data.env["?"]
		_current_blank_position = char_data.transform.origin


func _notify_blank_found() -> void:
	blank_found.emit(_current_blank_value, _current_blank_position)
	_current_blank_index = -1
	_current_blank_value = ""
	_current_blank_position = Vector2(-1.0, -1.0)


func set_parsing_blanks(value: bool) -> void:
	if parsing_blanks == value:
		return
	
	parsing_blanks = value
	
	if parsing_blanks:
		_current_blank_index = -1
		_current_blank_value = ""
		_current_blank_position = Vector2(-1.0, -1.0)
	
	# Make sure we notify about the final blank.
	if not parsing_blanks && not _current_blank_index == -1:
		_notify_blank_found()
