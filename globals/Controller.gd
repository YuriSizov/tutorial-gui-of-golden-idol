extends Node

signal level_initializing()
signal clue_selected(text: String)

# Can be used for data validation and global access.
var clues: PackedStringArray = PackedStringArray()
var blanks: PackedStringArray = PackedStringArray()


# Level management.

func initialize_level() -> void:
	clues.clear()
	blanks.clear()
	
	# Inform level components that they need to provide data for clues and
	# blanks. This will take exactly one frame. See also SourceDocument and
	# DossierDocument.
	level_initializing.emit()


func validate_level() -> void:
	# For debug purposes we check that the level data is actually valid and
	# the level is solvable.
	
	# TODO: We can also validate that the clues all fit the predefined width of corresponding blanks.
	# This is left as an exercise for the reader, but as a hint you can use TextLine to compute the
	# length of the shaped text.
	
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


# Level data management.

func register_clue(text: String) -> void:
	clues.push_back(text)


func notify_clue_selected(text: String) -> void:
	clue_selected.emit(text)


func register_blank(text: String) -> void:
	blanks.push_back(text)
