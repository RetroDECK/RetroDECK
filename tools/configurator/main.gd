extends Control

func _ready():
	var children = findElements(self, "Control")
	for n: Control in children: #iterate the children to grab focus on mouse hov
		if (n.focus_mode == FOCUS_ALL):
			n.mouse_entered.connect(_on_control_mouse_entered.bind(n))
	combine_tkeys()
	
		
func _input(event):
	if event.is_action_pressed("quit"):
		_exit()

func findElements(node: Node, className: String, result: Array = []) -> Array:
	if node.is_class(className):
		result.push_back(node)
	for child in node.get_children():
		result = findElements(child, className, result)
	return result

func _on_control_mouse_entered(control: Node):
	control.grab_focus()


func _on_quickresume_advanced_pressed():
	var popup = load("res://components/popup.tscn").instantiate() as Control
	popup.set_content("res://popup_content_test.tscn")
	$Background.add_child(popup)


func _on_exit_button_pressed():
	_exit()

func _exit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func _on_locale_selected(index):
	match index:
		0:
			TranslationServer.set_locale("en")
		1:
			TranslationServer.set_locale("it")
		2:
			TranslationServer.set_locale("de")
		3:
			TranslationServer.set_locale("se")
	combine_tkeys()
	
func combine_tkeys(): #More as a test
	$Background/MarginContainer/TabContainer/TK_SYSTEM/ScrollContainer/VBoxContainer/game_control_container/GridContainer/cheats.text = tr("TK_CHEATS") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_GRAPHICS/ScrollContainer/VBoxContainer/decorations_container/GridContainer/shaders.text = tr("TK_SHADERS") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_GRAPHICS/ScrollContainer/VBoxContainer/extra_container/GridContainer/tate_mode.text = tr("TK_TATE") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_CONTROLS/ScrollContainer/VBoxContainer/controls_container/hotkey_sound.text = tr("TK_HOTKEYSOUND") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_NETWORK/ScrollContainer/VBoxContainer/cheevos_container/cheevos_advanced_container/cheevos_hardcore.text = tr("TK_CHEEVOSHARDCORE") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_NETWORK/ScrollContainer/VBoxContainer/data_mng_container/saves_sync.text = tr("TK_SAVESSYNC") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_CONFIGURATOR/ScrollContainer/VBoxContainer/system_container/easter_eggs.text = tr("TK_EASTEREGGS") + " " + tr("TK_SOON")
