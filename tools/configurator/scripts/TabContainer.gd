extends TabContainer

var icon_width: int = 32
@onready var tcount: int = get_tab_count()-2

func _ready():
	focusFirstFocusableChild() #grab focus on first element to enable controller focusing
	%TabContainer.add_theme_icon_override("decrement",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0797.png"))
	%TabContainer.add_theme_icon_override("decrement_highlight",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0763.png"))
	%TabContainer.add_theme_icon_override("increment",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0798.png"))
	%TabContainer.add_theme_icon_override("increment_highlight",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0764.png"))
	if class_functions.font_select !=3:
		%TabContainer.add_theme_font_size_override("font_size", class_functions.font_tab_size)
	elif class_functions.font_select == 3:
		%TabContainer.add_theme_font_size_override("font_size", 15)
	else:
		%TabContainer.add_theme_font_size_override("font_size", class_functions.font_tab_size)
	set_tab_title(0, "  GLOBALS    ")
	set_tab_title(1, "  SYSTEM     ")
	set_tab_title(2, "   TOOLS      ")
	set_tab_title(3, "  SETTINGS   ")
	set_tab_title(4, "   ABOUT      ")
	set_tab_hidden(5, true)
	set_tab_icon(0, ResourceLoader.load("res://assets/icons/pixelitos/128/map-globe.png"))
	set_tab_icon_max_width(0,icon_width)
	set_tab_icon(1, ResourceLoader.load("res://assets/icons/pixelitos/128/preferences-system-windows.png"))
	set_tab_icon_max_width(1,icon_width)
	set_tab_icon(2, ResourceLoader.load("res://assets/icons/pixelitos/128/utilities-system-monitor.png"))
	set_tab_icon_max_width(2,icon_width)
	set_tab_icon(3, ResourceLoader.load("res://assets/icons/pixelitos/128/preferences-system-session-services.png"))
	set_tab_icon_max_width(3,icon_width)
	set_tab_icon(4, ResourceLoader.load("res://assets/icons/pixelitos/128/help-about.png"))
	set_tab_icon_max_width(4,icon_width)
	connect_focus_signals(self)
	%volume_effects_slider.value = class_functions.volume_effects

func connect_focus_signals(node):
	for child in node.get_children():
		if child is Button:
			child.focus_entered.connect(_on_button_focus_entered.bind(child))
			child.focus_exited.connect(_on_button_focus_exited.bind())
		elif child is Control:
			connect_focus_signals(child)

func _on_button_focus_exited() -> void:
	%pop_rtl.visible = false

func _on_button_focus_entered(button: Button):
	if button and class_functions.sound_effects:
		%AudioStreamPlayer2D.volume_db = class_functions.volume_effects
		%AudioStreamPlayer2D.play()
	if button and class_functions.rekku_state == false and button.has_meta("description"):
		%pop_rtl.visible = true
		%pop_rtl.text = button.get_meta("description")
	elif class_functions.rekku_state == false:
		%pop_rtl.visible = true
		%pop_rtl.text = "Hey, there's no description"

func _input(event):
	if (event.is_action_pressed("next_tab")):
		if current_tab == tcount:
			current_tab = 0
		else:
			self.select_next_available()
			focusFirstFocusableChild()
	if (event.is_action_pressed("previous_tab")):
		if current_tab == 0:
			current_tab = tcount
		else:	
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
