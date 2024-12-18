extends Control

var app_data := AppData.new()
var current_system := Emulator.new()
var press_time: float = 0.0
var is_reset_pressed: bool = false
var reset_result: Dictionary
@export var PRESS_DURATION: float = 3.0

func _ready():
	app_data = data_handler.app_data
	_connect_signals()
	
func _process(delta: float) -> void:
	if is_reset_pressed:
		press_time += delta
		%reset_progress.value = press_time / PRESS_DURATION * 100.0
	if press_time >= PRESS_DURATION:
		_do_complete()
		press_time = 0.0
		is_reset_pressed = false
		%reset_progress.value = 0.0
	
func _connect_signals() -> void:
	#TODO make for loops for each function linked to button function call
	# Change to  follow hoe TabGlobals Works
	%retroarch_button.pressed.connect(standard_buttons.bind(%retroarch_button,%system_gridcontainer, %action_gridcontainer))
	%mame_button.pressed.connect(standard_buttons.bind(%mame_button,%system_gridcontainer, %action_gridcontainer))
	%ruffle_button.pressed.connect(standard_buttons.bind(%ruffle_button,%system_gridcontainer, %action_gridcontainer))
	%melonds_button.pressed.connect(standard_buttons.bind(%melonds_button,%system_gridcontainer, %action_gridcontainer))
	%pcsx2_button.pressed.connect(standard_buttons.bind(%pcsx2_button,%system_gridcontainer, %action_gridcontainer))
	%duckstation_button.pressed.connect(standard_buttons.bind(%duckstation_button,%system_gridcontainer, %action_gridcontainer))
	%ppsspp_button.pressed.connect(standard_buttons.bind(%ppsspp_button,%system_gridcontainer, %action_gridcontainer))
	%vita3k_button.pressed.connect(standard_buttons.bind(%vita3k_button,%system_gridcontainer, %action_gridcontainer))
	%rpcs3_button.pressed.connect(standard_buttons.bind(%rpcs3_button,%system_gridcontainer, %action_gridcontainer))
	%ryujinx_button.pressed.connect(standard_buttons.bind(%ryujinx_button,%system_gridcontainer, %action_gridcontainer))
	%dolphin_button.pressed.connect(standard_buttons.bind(%dolphin_button,%system_gridcontainer, %action_gridcontainer))
	%primehack_button.pressed.connect(standard_buttons.bind(%primehack_button,%system_gridcontainer, %action_gridcontainer))
	%cemu_button.pressed.connect(standard_buttons.bind(%cemu_button,%system_gridcontainer, %action_gridcontainer))
	%xemu_button.pressed.connect(standard_buttons.bind(%xemu_button,%system_gridcontainer, %action_gridcontainer))
	%esde_button.pressed.connect(standard_buttons.bind(%esde_button,%system_gridcontainer, %action_gridcontainer))	
	%help_button.pressed.connect(_do_action.bind(%help_button))
	#%launch_button.pressed.connect(_do_action.bind(%launch_button))
	%launch_button.pressed.connect(_do_action.bind(%launch_button))
	%reset_button.button_down.connect(_do_action.bind(%reset_button))
	%reset_button.button_up.connect(_on_Button_released.bind(%reset_progress))
	%rpcs3_firmware_button.pressed.connect(_do_action.bind(%rpcs3_firmware_button))
	%vita3k_firmware_button.pressed.connect(_do_action.bind(%vita3k_firmware_button))
	%retroarch_quick_resume_button.pressed.connect(class_functions.run_function.bind(%retroarch_quick_resume_button, "quick_resume"))
	
func standard_buttons(button: Button, buttons_gridcontainer: GridContainer, hidden_gridcontainer: GridContainer) -> void:
	current_system = app_data.emulators[button.text.to_lower()]
	%reset_button.text="RESET"
	match button.name:
		"vita3k_button":
			%vita3k_firmware_button.visible = true
		"rpcs3_button":
			%rpcs3_firmware_button.visible = true
		"retroarch_button":
			%retroarch_quick_resume_button.visible = true
		_:
			%vita3k_firmware_button.visible = false
			%rpcs3_firmware_button.visible = false
			%retroarch_quick_resume_button.visible = false
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
	is_reset_pressed = false
	%reset_progress.visible = false
	press_time = 0.0
	progress.value = 0.0
		
func _do_action(button: Button) -> void:
	var original_txt = button.text
	match [button.name, current_system.name]:
		["help_button", current_system.name]:
			if class_functions.desktop_mode != "gamescope":
				print ("URL %s" %current_system.url)
				class_functions.logger("i", "Launching " + current_system.name + " Help")
				class_functions.launch_help(current_system.url)
			else:
				button.text = "Help only works in Desktop Mode"
				await class_functions.wait(3.0)
				button.text = original_txt
		["launch_button", current_system.name]:
			class_functions.logger("i", "Launching " + current_system.name)
			var launch = class_functions.execute_command(current_system.launch,[], false)
			class_functions.logger("d", "Exit Code: " + str(launch["exit_code"]))
		["reset_button", current_system.name]:
			is_reset_pressed = true
			%reset_progress.visible = true
		["rpcs3_firmware_button", current_system.name]:
			class_functions.logger("i", "Firmware install " + current_system.name)
			var launch = class_functions.execute_command(class_functions.wrapper_command,["update_rpcs3_firmware"], false)
			class_functions.logger("d", "Exit Code: " + str(launch["exit_code"]))
		["vita3k_firmware_button", current_system.name]:
			class_functions.logger("i", "Firmware install " + current_system.name)
			var launch = class_functions.execute_command(class_functions.wrapper_command,["update_vita3k_firmware"], false)
			class_functions.logger("d", "Exit Code: " + str(launch["exit_code"]))

func _do_complete() ->void:
	if is_reset_pressed:
		var tmp_txt = %reset_button.text
		%reset_button.text = "RESETTING-NOW"
		class_functions.logger("i", "Resetting " + current_system.name)
		var parameters = ["prepare_component","reset",current_system.name]
		reset_result = await class_functions.run_thread_command(class_functions.wrapper_command,parameters, false)
		class_functions.logger("d", "Exit Code: " + str(reset_result["exit_code"]))
		%reset_button.text = "RESET COMPLETED"
		await class_functions.wait(3.0)
		%reset_button.text = tmp_txt
