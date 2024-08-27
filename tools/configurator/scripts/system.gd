extends Control

var app_data := AppData.new()
var current_system := Emulator.new()

func _ready():
	app_data = data_handler.app_data
	_connect_signals()
	
func _connect_signals() -> void:
	%retroarch_button.pressed.connect(_hide_show_buttons.bind(%retroarch_button,%system_gridcontainer, %action_gridcontainer))
	%mame_button.pressed.connect(_hide_show_buttons.bind(%mame_button,%system_gridcontainer, %action_gridcontainer))
	%ruffle_button.pressed.connect(_hide_show_buttons.bind(%ruffle_button,%system_gridcontainer, %action_gridcontainer))
	%melonds_button.pressed.connect(_hide_show_buttons.bind(%melonds_button,%system_gridcontainer, %action_gridcontainer))
	%pcsx2_button.pressed.connect(_hide_show_buttons.bind(%pcsx2_button,%system_gridcontainer, %action_gridcontainer))
	%duckstation_button.pressed.connect(_hide_show_buttons.bind(%duckstation_button,%system_gridcontainer, %action_gridcontainer))
	%ppsspp_button.pressed.connect(_hide_show_buttons.bind(%ppsspp_button,%system_gridcontainer, %action_gridcontainer))
	%vita3k_button.pressed.connect(_hide_show_buttons.bind(%vita3k_button,%system_gridcontainer, %action_gridcontainer))
	%rpcs3_button.pressed.connect(_hide_show_buttons.bind(%rpcs3_button,%system_gridcontainer, %action_gridcontainer))
	%ryujinx_button.pressed.connect(_hide_show_buttons.bind(%ryujinx_button,%system_gridcontainer, %action_gridcontainer))
	%dolphin_button.pressed.connect(_hide_show_buttons.bind(%primehack_button,%system_gridcontainer, %action_gridcontainer))
	%cemu_button.pressed.connect(_hide_show_buttons.bind(%cemu_button,%system_gridcontainer, %action_gridcontainer))
	%xemu_button.pressed.connect(_hide_show_buttons.bind(%xemu_button,%system_gridcontainer, %action_gridcontainer))
	%esde_button.pressed.connect(_hide_show_buttons.bind(%esde_button,%system_gridcontainer, %action_gridcontainer))	
	%help_button.pressed.connect(_do_action.bind(%help_button))
	%launch_button.pressed.connect(_do_action.bind(%launch_button))

func _hide_show_buttons(button: Button, buttons_gridcontainer: GridContainer, hidden_gridcontainer: GridContainer) -> void:
	current_system = app_data.emulators[button.text.to_lower()]
	match button.name:
		"retroarch_button", "mame_button", "ruffle_button", "melonds_button", "pcsx2_button", "duckstation_button", \
		"ppsspp_button", "vita3k_button", "rpcs3_button", "ryujinx_button", "dolphin_button", "primehack_button", \
		"cemu_button", "xemu_button", "esde_button":
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

func _do_action(button: Button) -> void:

	match [button.name, current_system.name]:
		["help_button", current_system.name]:
			class_functions.log_parameters[2] = class_functions.log_text + "Launching " + current_system.name + " Help"
			class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
			class_functions.launch_help("https://retrodeck.readthedocs.io/en/latest/wiki_emulator_guides/retroarch/retroarch-guide/")
		["launch_button", current_system.name]:
			class_functions.log_parameters[2] = class_functions.log_text + "Launching " + current_system.name
			class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
			var launch = class_functions.execute_command(current_system.launch,[], false)
			#Log the result TODO
			class_functions.log_parameters[2] = class_functions.log_text + "Exit Code: " + str(launch["exit_code"])
			class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
			
		
