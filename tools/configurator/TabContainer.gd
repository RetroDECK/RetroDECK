extends TabContainer

var icon_width: int = 32
@onready var tcount: int = get_tab_count()-1
var l1_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0797.png")
var r1_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0798.png")


func _ready():
	focusFirstFocusableChild() #grab focus on first element to enable controller focusing
	%TabContainer.add_theme_icon_override("decrement",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0797.png"))
	%TabContainer.add_theme_icon_override("decrement_highlight",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0763.png"))
	%TabContainer.add_theme_icon_override("increment",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0798.png"))
	%TabContainer.add_theme_icon_override("increment_highlight",ResourceLoader.load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0764.png"))
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
	#%TK_GRAPHICS.name="BOB"
	connect_focus_signals(self)
	
func connect_focus_signals(node):		
	for child in node.get_children():
		if child is Button:
			child.focus_entered.connect(_on_Button_focus_entered.bind(child))
		elif child is Control:
			connect_focus_signals(child)

func _on_Button_focus_entered(button: Button):
	if button:
		%AudioStreamPlayer2D.play()

func _input(event):
	if (event.is_action_pressed("next_tab")):
		%r1_button.texture_normal = %r1_button.texture_pressed
		if current_tab == tcount:
			current_tab = 0
		else:
			self.select_next_available()
			focusFirstFocusableChild()
	else:
		%r1_button.texture_normal = r1_button_texture
	if (event.is_action_pressed("previous_tab")):
		%l1_button.texture_normal = %l1_button.texture_pressed
		if current_tab == 0:
			current_tab = tcount
		else:	
			self.select_previous_available()
			focusFirstFocusableChild()
	else:
		%l1_button.texture_normal = l1_button_texture

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
