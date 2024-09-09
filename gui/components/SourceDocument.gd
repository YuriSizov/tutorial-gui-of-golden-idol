@tool
class_name SourceDocument extends RichTextLabel

var _clues: Array[SourceClue] = []
var _clues_index_map: Dictionary = {}
var _clues_parsed: bool = false
var _clues_text_buffer: TextLine = TextLine.new()


func _ready() -> void:
	var source_clue_effect: SourceClueEffect = custom_effects[0]
	source_clue_effect.clue_found.connect(_handle_new_clue)
	
	resized.connect(_prepare_clues.bind(true))
	
	if not Engine.is_editor_hint():
		Controller.level_initializing.connect(_prepare_clues.bind(false))


func _draw() -> void:
	# This must be done while drawing, see the note in _prepare_clues() below.
	_process_clues()
	
	# Underline the clues in text, using the custom clue color and adjustible thickness.
	
	var underline_color := get_theme_color("clue_color", "RichTextLabel")
	var underline_size := get_theme_constant("underline_size", "RichTextLabel")
	
	for clue_data in _clues:
		if clue_data.selected:
			continue # Don't draw the underline for clues that the player has already clicked on.
		
		var underline_rect := Rect2()
		underline_rect.position = Vector2(clue_data.rect.position.x, clue_data.rect.end.y + _clues_text_buffer.get_line_underline_position())
		underline_rect.size = Vector2(clue_data.rect.size.x, underline_size)
		
		draw_rect(underline_rect, underline_color)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		# To have more control and make the layout simpler we don't use meta/url tags,
		# so we must emulate their behavior by handling clicks ourselves.
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			for clue_data in _clues:
				if clue_data.rect.has_point(mb.position):
					_handle_clue_clicked(clue_data)
					break
	
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		
		# Control nodes don't expose to scripting a way to override the current cursor
		# (a virtual counterpart to get_cursor_shape()). So we update the property manually.
		
		var hovering_clue := false
		for clue_data in _clues:
			if clue_data.rect.has_point(mm.position):
				hovering_clue = true
				break
		
		if hovering_clue:
			mouse_default_cursor_shape = CURSOR_POINTING_HAND
		else:
			mouse_default_cursor_shape = CURSOR_ARROW


# Clue management.

func _prepare_clues(update_only: bool) -> void:
	if not update_only:
		_clues.clear()
		_clues_index_map.clear()
		_clues_parsed = false
	
	# We want to hijack the effect processing to extract some data for gameplay
	# purposes. We have to account for the fact that the effect is being processed
	# constantly, and that each line of the RichTextLabel node is processed 3
	# times (shadow, outline, color passes) per frame.
	#
	# To work within these limitations we manually enable parsing for just one
	# frame. We don't expect this data to change dynamically, so that's sufficient.
	
	var source_clue_effect: SourceClueEffect = custom_effects[0]
	source_clue_effect.parsing_clues = true


func _process_clues() -> void:
	var source_clue_effect: SourceClueEffect = custom_effects[0]
	
	if source_clue_effect.parsing_clues:
		source_clue_effect.parsing_clues = false
		_clues_parsed = true


func _handle_new_clue(from_index: int, to_index: int, at_position: Vector2) -> void:
	# The given indices already account for tag stripping. We use the parsed text to extract
	# the exact string.
	var clue_text := get_parsed_text().substr(from_index, to_index - from_index)
	
	# The RichTextLabel node doesn't expose a way to access its underlying text buffers. We
	# use our own buffer that takes the string value and font properties, and gives us a good
	# estimate for the size of the rendered text.
	_clues_text_buffer.clear()
	_clues_text_buffer.add_string(clue_text, get_theme_font("normal_font"), get_theme_font_size("normal_font_size"))
	
	var clue_rect := Rect2()
	clue_rect.size = _clues_text_buffer.get_size()
	clue_rect.position = at_position - Vector2(0.0, clue_rect.size.y) # Base position is at the baseline of the string.
	
	var clue_data := SourceClue.new()
	clue_data.text = clue_text
	clue_data.rect = clue_rect
	clue_data.span = Vector2i(from_index, to_index)
	
	# Only updating data now, clues already registered.
	if _clues_parsed:
		_clues_index_map[clue_data.span].rect = clue_data.rect
		return
	
	_clues.push_back(clue_data)
	_clues_index_map[clue_data.span] = clue_data
	prints("new clue", clue_data)
	
	if not Engine.is_editor_hint():
		Controller.register_clue(clue_data.text)


func _handle_clue_clicked(clue_data: SourceClue) -> void:
	clue_data.selected = true
	prints("clicked", clue_data)
	
	if not Engine.is_editor_hint():
		Controller.notify_clue_selected(clue_data.text)


class SourceClue:
	var text: String = ""
	var rect: Rect2 = Rect2()
	var span: Vector2i = Vector2i(-1, -1)
	
	var selected: bool = false
	
	
	func _to_string() -> String:
		return "(%d:%d, %s) %s" % [ span.x, span.y, rect, text ]
