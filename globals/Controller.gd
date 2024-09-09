extends Node

signal level_initializing()
signal clue_selected(text: String)

var clues: PackedStringArray = PackedStringArray()
var blanks: PackedStringArray = PackedStringArray()


func initialize_level() -> void:
	clues.clear()
	blanks.clear()
	
	level_initializing.emit()


func validate_level() -> void:
	var missing_clues: PackedStringArray = PackedStringArray()
	
	for blank_text in blanks:
		if blank_text not in clues:
			missing_clues.push_back(blank_text)
	
	if not missing_clues.is_empty():
		printerr("Level Unsolvable: Not all required clues are present! Missing clues:")
		for clue in missing_clues:
			printerr(" - %s" % [ clue ])
	else:
		print("Level Valid!")


func register_clue(text: String) -> void:
	clues.push_back(text)


func notify_clue_selected(text: String) -> void:
	clue_selected.emit(text)


func register_blank(text: String) -> void:
	blanks.push_back(text)
