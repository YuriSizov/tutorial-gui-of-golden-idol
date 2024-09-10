# Implements the [clue][/clue] tag for the RichTextLabel node.
#
# This tag has no arguments and contains the word that is registered as a clue.
# Clues are highlighted and underlined, although the underline is removed when
# the clue is acquired for the first time. Clues are clickable.

@tool
class_name SourceClueEffect extends RichTextEffect

signal clue_found(from_index: int, to_index: int, position: Vector2)

var bbcode: String = "clue"
var parsing_clues: bool = false:
	set = set_parsing_clues

var _current_clue_index: int = -1
var _current_clue_end: int = -1
var _current_clue_position: Vector2 = Vector2(-1.0, -1.0)


func _process_custom_fx(char_data: CharFXTransform) -> bool:
	# Do data parsing while drawing and updating effects, if this flag is enabled.
	if parsing_clues:
		_process_clue(char_data)
	
	char_data.color = ThemeDB.get_project_theme().get_color("clue_color", "RichTextLabel")
	return true


func _process_clue(char_data: CharFXTransform) -> void:
	# The outline flag is set only for shadow and outline passes, but not the color pass.
	# We use this fact to make sure the processing is only done once per line.
	if not parsing_clues || char_data.outline:
		return
	
	# Rich text effects don't contain the data for the entire affected string. So we
	# improvise using the relative index, which is available.
	#
	# If the incoming index is set to zero, flush the collected clue and notify the
	# owner label about it.
	if char_data.relative_index == 0 && not _current_clue_index == -1:
		_notify_clue_found()
	
	# Collect the clue. Store the starting data if we're at the beginning of it
	# and always update the ending index.
	if char_data.relative_index == 0:
		_current_clue_index = char_data.range.x
		_current_clue_position = char_data.transform.origin
	_current_clue_end = char_data.range.y


func _notify_clue_found() -> void:
	clue_found.emit(_current_clue_index, _current_clue_end, _current_clue_position)
	_current_clue_index = -1
	_current_clue_end = -1
	_current_clue_position = Vector2(-1.0, -1.0)


func set_parsing_clues(value: bool) -> void:
	if parsing_clues == value:
		return
	
	parsing_clues = value
	
	if parsing_clues:
		_current_clue_index = -1
		_current_clue_end = -1
		_current_clue_position = Vector2(-1.0, -1.0)
	
	# Make sure we notify about the final clue.
	if not parsing_clues && not _current_clue_index == -1:
		_notify_clue_found()
