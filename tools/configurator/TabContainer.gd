extends TabContainer

var icon_width: int = 32

func _ready():
	focusFirstFocusableChild() #grab focus on first element to enable controller focusing
	%TabContainer.add_theme_icon_override("decrement",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0797.png"))
	%TabContainer.add_theme_icon_override("decrement_highlight",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0763.png"))
	%TabContainer.add_theme_icon_override("increment",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0798.png"))
	%TabContainer.add_theme_icon_override("increment_highlight",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0764.png"))
	set_tab_icon(0, ResourceLoader.load("res://assets/icons/pixelitos/128/applications-graphics.png"))
	set_tab_icon_max_width(0,icon_width)
	set_tab_icon(1, ResourceLoader.load("res://assets/icons/pixelitos/128/preferences-system-windows.png"))
	set_tab_icon_max_width(1,icon_width)
	set_tab_icon(2, ResourceLoader.load("res://assets/icons/pixelitos/128/utilities-tweak-tool.png"))
	set_tab_icon_max_width(2,icon_width)
	set_tab_icon(3, ResourceLoader.load("res://assets/icons/pixelitos/128/network-workgroup.png"))
	set_tab_icon_max_width(3,icon_width)
	set_tab_icon(4, ResourceLoader.load("res://assets/icons/pixelitos/128/utilities-system-monitor.png"))
	set_tab_icon_max_width(4,icon_width)
	set_tab_icon(5, ResourceLoader.load("res://assets/icons/pixelitos/128/preferences-system-session-services.png"))
	set_tab_icon_max_width(5,icon_width)
	set_tab_icon(6, ResourceLoader.load("res://assets/icons/pixelitos/128/help-about.png"))
	set_tab_icon_max_width(6,icon_width)
#
func _input(event):
	if (event.is_action_pressed("next_tab")):
		self.select_next_available()
		focusFirstFocusableChild()
		
	if (event.is_action_pressed("previous_tab")):
		self.select_previous_available()
		focusFirstFocusableChild()
	
func focusFirstFocusableChild():
	var children = findElements(get_current_tab_control(), "Control")
	for n: Control in children:
		if (n.focus_mode == FOCUS_ALL):
			n.grab_focus.call_deferred()
			break
	
func findElements(node: Node, className: String, result: Array = []) -> Array:
	if node.is_class(className):
		result.push_back(node)
	for child in node.get_children():
		result = findElements(child, className, result)
	return result
