# This is a custom texture type that can draw a stylebox, namely StyleBoxFlat
# in any place where a texture can be drawn normally. This class is provided
# for convenience, as we need a texture for RichTextLabel nodes, and a stylebox
# is the easiest way to have a parametric texture for a panel in the engine.
#
# In a real project you will probably use some nine-patch asset, although that
# also doesn't have a dedicated texture type... Which can also be worked around
# with a solution such as below.

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
