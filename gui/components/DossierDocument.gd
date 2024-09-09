@tool
class_name DossierDocument extends RichTextLabel

const BLUE_BLANK_TEXTURE := preload("res://gui/theme/blanks/blue_blank_texture.tres")

var _blanks: Array[DossierBlank] = []
var _blanks_text_buffer: TextLine = TextLine.new()

@onready var _result_label: Label = %ResultLabel


func _ready() -> void:
	var dossier_blank_effect: DossierBlankEffect = custom_effects[0]
	dossier_blank_effect.blank_found.connect(_handle_new_blank)
	
	_validate_dossier()
	
	if not Engine.is_editor_hint():
		Controller.level_initializing.connect(_prepare_blanks)


func _draw() -> void:
	# This must be done while drawing, see the note in _prepare_blanks() below.
	_process_blanks()
	
	# Draw text buffers for blanks with assigned values.
	
	var blank_color := get_theme_color("default_color")
	
	for blank_data in _blanks:
		if blank_data.text_buffer:
			var label_position := blank_data.rect.position
			label_position += (blank_data.rect.size - blank_data.text_buffer.get_size()) / 2.0
			
			blank_data.text_buffer.draw(get_canvas_item(), label_position, blank_color)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		# To have more control and make the layout simpler we don't use meta/url tags,
		# so we must emulate their behavior by handling clicks ourselves.
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_RIGHT:
			for blank_data in _blanks:
				if blank_data.rect.has_point(mb.position):
					_handle_blank_clicked(blank_data)
					break


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is not WordBank.WordBankDragData:
		return false
	
	for blank_data in _blanks:
		if blank_data.rect.has_point(at_position):
			return true
	
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data is not WordBank.WordBankDragData:
		return
	
	for blank_data in _blanks:
		if blank_data.rect.has_point(at_position):
			var text_value := (data as WordBank.WordBankDragData).value
			_handle_blank_assigned(blank_data, text_value)
			break


# Blank management.

func _prepare_blanks() -> void:
	_blanks.clear()
	
	# We want to hijack the effect processing to extract some data for gameplay
	# purposes. We have to account for the fact that the effect is being processed
	# constantly, and that each line of the RichTextLabel node is processed 3
	# times (shadow, outline, color passes) per frame.
	#
	# To work within these limitations we manually enable parsing for just one
	# frame. We don't expect this data to change dynamically, so that's sufficient.
	
	var dossier_blank_effect: DossierBlankEffect = custom_effects[0]
	dossier_blank_effect.parsing_blanks = true


func _process_blanks() -> void:
	var dossier_blank_effect: DossierBlankEffect = custom_effects[0]
	
	if dossier_blank_effect.parsing_blanks:
		dossier_blank_effect.parsing_blanks = false
		_validate_dossier()


func _handle_new_blank(blank_text: String, at_position: Vector2) -> void:
	# The RichTextLabel node doesn't expose a way to access its underlying text buffers. We
	# use our own buffer that takes the string value and font properties, and gives us a good
	# estimate for the size of the rendered text.
	_blanks_text_buffer.clear()
	_blanks_text_buffer.add_string(blank_text, get_theme_font("normal_font"), get_theme_font_size("normal_font_size"))
	
	var blank_rect := Rect2()
	blank_rect.size = BLUE_BLANK_TEXTURE.get_size()
	blank_rect.position = at_position
	blank_rect.position.y -= (_blanks_text_buffer.get_line_ascent() - _blanks_text_buffer.get_line_descent() + blank_rect.size.y) / 2.0
	
	var blank_data := DossierBlank.new()
	blank_data.allowed_text = blank_text.split(";", false)
	blank_data.rect = blank_rect
	
	_blanks.push_back(blank_data)
	prints("new blank", blank_data)
	
	if not Engine.is_editor_hint():
		for text_value in blank_data.allowed_text:
			Controller.register_blank(text_value)


func _handle_blank_assigned(blank_data: DossierBlank, text_value: String) -> void:
	blank_data.set_assigned_text(text_value, get_theme_font("normal_font"), get_theme_font_size("normal_font_size"))
	prints("assigned", blank_data)
	
	_validate_dossier()


func _handle_blank_clicked(blank_data: DossierBlank) -> void:
	blank_data.set_assigned_text("", get_theme_font("normal_font"), get_theme_font_size("normal_font_size"))
	prints("clicked", blank_data)
	
	_validate_dossier()


# Dossier management.

func _validate_dossier() -> void:
	var total_count := _blanks.size()
	var valid_count := 0
	
	for blank_data in _blanks:
		if blank_data.is_assigned_valid():
			valid_count += 1
	
	_result_label.text = "%d/%d" % [ valid_count, total_count ]
	if total_count == 0:
		_result_label.remove_theme_color_override("font_color")
	elif valid_count < total_count:
		_result_label.add_theme_color_override("font_color", get_theme_color("failure_color", "DossierResultLabel"))
	else:
		_result_label.add_theme_color_override("font_color", get_theme_color("success_color", "DossierResultLabel"))



class DossierBlank:
	var allowed_text: PackedStringArray = PackedStringArray()
	var rect: Rect2 = Rect2()
	
	var _assigned_text: String = ""
	var text_buffer: TextLine = TextLine.new()
	
	
	func _to_string() -> String:
		return "(%s) %s <- %s" % [ rect, allowed_text, _assigned_text ]
	
	
	func is_assigned_valid() -> bool:
		return _assigned_text in allowed_text
	
	
	func set_assigned_text(value: String, font: Font, font_size: int) -> void:
		if _assigned_text == value:
			return
		
		_assigned_text = value
		text_buffer.clear()
		text_buffer.add_string(_assigned_text, font, font_size)
