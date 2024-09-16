extends MarginContainer

var press_time: float = 0.0
var is_swap_pressed: bool = false
var PRESS_DURATION: float = 3.0

func _ready():
	_connect_signals()

func _process(delta: float) -> void:
	if is_swap_pressed and class_functions.abxy_state == "mixed":
		press_time += delta
		%button_swap_progress.value = press_time / PRESS_DURATION * 100.0
	if press_time >= PRESS_DURATION:
		_do_complete()
		press_time = 0.0
		is_swap_pressed = false
		%button_swap_progress.value = 0.0

func _connect_signals():
	%quick_resume_button.pressed.connect(class_functions.run_function.bind(%quick_resume_button))
	%widescreen_button.pressed.connect(class_functions.run_function.bind(%widescreen_button))
	%button_swap_button.button_down.connect(_do_action.bind(%button_swap_button))
	%button_swap_button.button_up.connect(_on_Button_released.bind(%button_swap_progress))
	%button_swap_button.pressed.connect(class_functions.run_function.bind(%button_swap_button))

func _on_Button_released(progress: ProgressBar) -> void:
	is_swap_pressed = false
	%button_swap_progress.visible = false
	press_time = 0.0
	progress.value = 0.0
	
func _do_action(button: Button) -> void:
	match button.name:
		"button_swap_button":
			is_swap_pressed = true
			%button_swap_progress.visible = true

func _do_complete() ->void:
	if is_swap_pressed:
		class_functions.abxy_state = "false"
		%button_swap_button.toggle_mode = true
		%button_swap_button.pressed.connect(class_functions.run_function.bind(%button_swap_button))
		#class_functions.logger("i", "Resetting " + current_system.name)
		#var parameters = ["prepare_component","reset",current_system.name]
		#reset_result = await class_functions.run_thread_command(class_functions.wrapper_command,parameters, false)
		#class_functions.logger("d", "Exit Code: " + str(reset_result["exit_code"]))
		#await class_functions.wait(3.0)
