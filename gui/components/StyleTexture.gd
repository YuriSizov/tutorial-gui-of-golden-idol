@tool
class_name StyleTexture extends Texture2D

@export var stylebox: StyleBox = null
@export var width: int = 80
@export var height: int = 18

func _draw_rect(to_canvas_item: RID, rect: Rect2, _tile: bool, _modulate: Color, _transpose: bool) -> void:
	if not stylebox:
		return
	
	stylebox.draw(to_canvas_item, rect)


func _get_height() -> int:
	return height


func _get_width() -> int:
	return width
