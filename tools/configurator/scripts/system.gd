extends Control

var app_data := AppData.new()

func _ready():
	app_data = data_handler.app_data
	_connect_signals()
	
func _connect_signals() -> void:
	%retroarch_button.pressed.connect(_hide_show_buttons.bind(%retroarch_button,%system_gridcontainer, %action_gridcontainer))
	
func _hide_show_buttons(button: Button, buttons_gridcontainer: GridContainer, hidden_gridcontainer: GridContainer) -> void:
	match button.name:
		"retroarch_button", "borders_button", "button_layout":
			hidden_gridcontainer.visible = true
			if button.toggle_mode == false:
				for i in range(buttons_gridcontainer.get_child_count()):
					var child = buttons_gridcontainer.get_child(i)        
					if child is Button and child != button:
						child.visible=false
			elif button.toggle_mode == true and hidden_gridcontainer.visible == true:
				hidden_gridcontainer.visible = false
				for i in range(buttons_gridcontainer.get_child_count()):
					var child = buttons_gridcontainer.get_child(i)        
					if child is Button:
						child.visible=true
						child.toggle_mode = false
			if hidden_gridcontainer.visible == true:
				button.toggle_mode = true
	
