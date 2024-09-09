class_name WordBank extends HFlowContainer

const ENTRY_SCENE := preload("res://gui/components/WordBankEntry.tscn")

var _clues: PackedStringArray = PackedStringArray()


func _ready() -> void:
	if not Engine.is_editor_hint():
		Controller.clue_selected.connect(_add_selected_clue)


# Clue management.

func _add_selected_clue(text: String) -> void:
	if _clues.has(text):
		return
	
	var label := ENTRY_SCENE.instantiate()
	label.text = text
	add_child(label)
	
	label.set_drag_forwarding(
		_get_clue_drag_data.bind(text),
		Callable(),
		Callable()
	)
	
	_clues.push_back(text)


func _get_clue_drag_data(_at_position:Vector2, text: String) -> Variant:
	var data := WordBankDragData.new()
	data.value = text
	
	var preview := ENTRY_SCENE.instantiate()
	preview.text = text
	set_drag_preview(preview)
	
	return data


class WordBankDragData:
	var value: String = ""
