extends TabContainer

func _ready():
	focusFirstFocusableChild() #grab focus on first element to enable controller focusing

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
