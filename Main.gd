extends MarginContainer


func _ready() -> void:
	# This method is executed when all default nodes, nodes defined in
	# the Main.tscn scene, are mounted to the scene tree and ready. It's
	# a perfect place to initialize base environment for your project,
	# like loading the main menu or the intro level.
	
	# Don't execute in editor, though, if this script is ever made @tool.
	if not Engine.is_editor_hint():
		Controller.initialize_level()
		await get_tree().process_frame # We need one frame to perform some parsing.
		Controller.validate_level()
