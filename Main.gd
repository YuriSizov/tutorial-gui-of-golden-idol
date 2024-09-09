extends MarginContainer


func _ready() -> void:
	if not Engine.is_editor_hint():
		Controller.initialize_level()
		await get_tree().process_frame
		Controller.validate_level()
