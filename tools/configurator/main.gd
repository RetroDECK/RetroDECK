extends Control

func _ready():
	$MarginContainer/TabContainer/System/ScrollContainer/VBoxContainer/game_control_container/GridContainer/resume.grab_focus() #Required to enable controller focusing
	var children = findElements(self, "Control")
	#print(children)
	for n: Control in children:
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
