extends Control

func _ready():
	var children = findElements(self, "Control")
	for n: Control in children: #iterate the children to grab focus on mouse hov
		if (n.focus_mode != FOCUS_NONE):
			n.mouse_entered.connect(_on_control_mouse_entered.bind(n))

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()

func findElements(node: Node, className: String, result: Array = []) -> Array:
	if node.is_class(className):
		result.push_back(node)
	for child in node.get_children():
		result = findElements(child, className, result)
	return result

func _on_control_mouse_entered(control: Node):
	control.grab_focus()
