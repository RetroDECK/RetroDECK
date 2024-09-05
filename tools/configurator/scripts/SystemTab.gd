extends Control

var app_data := AppData.new()
var current_system := Emulator.new()
var press_time: float = 0.0
var is_launch_pressed: bool = false
var is_reset_pressed: bool = false
var reset_result: Dictionary
@export var PRESS_DURATION: float = 3.0

func _ready():
	app_data = data_handler.app_data
	_connect_signals()
	
func _process(delta: float) -> void:
	if is_launch_pressed:
		press_time += delta
		%launch_progress.value = press_time / PRESS_DURATION * 100.0
	if is_reset_pressed:
		press_time += delta
		%reset_progress.value = press_time / PRESS_DURATION * 100.0
	if press_time >= PRESS_DURATION:
		_do_complete()
		press_time = 0.0
		is_launch_pressed = false
		is_reset_pressed = false
		%launch_progress.value = 0.0
		%reset_progress.value = 0.0
	
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
	%dolphin_button.pressed.connect(_hide_show_buttons.bind(%dolphin_button,%system_gridcontainer, %action_gridcontainer))
	%primehack_button.pressed.connect(_hide_show_buttons.bind(%primehack_button,%system_gridcontainer, %action_gridcontainer))
	%cemu_button.pressed.connect(_hide_show_buttons.bind(%cemu_button,%system_gridcontainer, %action_gridcontainer))
	%xemu_button.pressed.connect(_hide_show_buttons.bind(%xemu_button,%system_gridcontainer, %action_gridcontainer))
	%esde_button.pressed.connect(_hide_show_buttons.bind(%esde_button,%system_gridcontainer, %action_gridcontainer))	
	%help_button.pressed.connect(_do_action.bind(%help_button))
	#%launch_button.pressed.connect(_do_action.bind(%launch_button))
	%launch_button.button_down.connect(_do_action.bind(%launch_button))
	%launch_button.button_up.connect(_on_Button_released.bind(%launch_progress))
	%reset_button.button_down.connect(_do_action.bind(%reset_button))
	%reset_button.button_up.connect(_on_Button_released.bind(%reset_progress))
	
func _hide_show_buttons(button: Button, buttons_gridcontainer: GridContainer, hidden_gridcontainer: GridContainer) -> void:
	current_system = app_data.emulators[button.text.to_lower()]
	match button.name:
		"retroarch_button", "mame_button", "ruffle_button", "melonds_button", "pcsx2_button", "duckstation_button", \
		"ppsspp_button", "vita3k_button", "rpcs3_button", "ryujinx_button", "dolphin_button", "primehack_button", \
		"cemu_button", "xemu_button", "esde_button":
			%reset_button.text="RESET"
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

func _on_Button_released(progress: ProgressBar) -> void:
	is_launch_pressed = false
	is_reset_pressed = false
	press_time = 0.0
	progress.value = 0.0
		
func _do_action(button: Button) -> void:
	match [button.name, current_system.name]:
		["help_button", current_system.name]:
			class_functions.log_parameters[2] = class_functions.log_text + "Launching " + current_system.name + " Help"
			class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
			class_functions.launch_help(current_system.url)
		["launch_button", current_system.name]:
			is_launch_pressed = true
		["reset_button", current_system.name]:
			is_reset_pressed = true

func _do_complete() ->void:
	if is_launch_pressed:
		class_functions.log_parameters[2] = class_functions.log_text + "Launching " + current_system.name
		class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
		var launch = class_functions.execute_command(current_system.launch,[], false)
		class_functions.log_parameters[2] = class_functions.log_text + "Exit Code: " + str(launch["exit_code"])
		class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
	if is_reset_pressed:
		var parameters = ["prepare_component","reset",current_system.name]
		%reset_button.text = "RESETTING-NOW"
		class_functions.log_parameters[2] = class_functions.log_text + "Resetting " + current_system.name
		class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
		await run_thread_command(class_functions.wrapper_command,parameters, false)
		class_functions.log_parameters[2] = class_functions.log_text + "Exit Code: " + str(reset_result["exit_code"])
		class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
		%reset_button.text = "RESET COMPLETED"

func run_thread_command(command: String, parameters: Array, console: bool) -> void:
	reset_result = await class_functions.run_command_in_thread(command, parameters, console)
