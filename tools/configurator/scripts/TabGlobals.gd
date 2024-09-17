extends MarginContainer

var press_time: float = 0.0
var is_state_pressed: bool = false
var PRESS_DURATION: float = 3.0

func _ready():
	_connect_signals()

func _process(delta: float) -> void:
	update_progress(delta, %ask_to_exit_progress, %ask_to_exit_button, class_functions.ask_to_exit_state)
	update_progress(delta, %border_progress, %border_button, class_functions.border_state)
	update_progress(delta, %widescreen_progress, %widescreen_button, class_functions.widescreen_state)
	update_progress(delta, %quick_rewind_progress, %quick_rewind_button, class_functions.quick_rewind_state)

func update_progress(delta: float, progress: ProgressBar, button: Button, state: String) -> void:
	if press_time >= PRESS_DURATION:
		#_do_complete(button)
		print ("Progress Bar: %s Button: %s" % [progress.name, button.name])
		press_time = 0.0
		is_state_pressed = false
		progress.value = 0.0
	elif is_state_pressed and state == "mixed":
		press_time += delta
		progress.value = press_time / PRESS_DURATION * 100.0

func _connect_signals():
	%quick_resume_button.pressed.connect(class_functions.run_function.bind(%quick_resume_button, "quick_resume"))
	%button_swap_button.button_down.connect(_do_action.bind(%button_swap_progress))
	%button_swap_button.button_up.connect(_on_button_released.bind(%button_swap_progress))
	%button_swap_button.pressed.connect(class_functions.run_function.bind(%button_swap_button, "abxy_button_swap"))
	%ask_to_exit_button.button_down.connect(_do_action.bind(%ask_to_exit_progress))
	%ask_to_exit_button.button_up.connect(_on_button_released.bind(%ask_to_exit_progress))
	%ask_to_exit_button.pressed.connect(class_functions.run_function.bind(%ask_to_exit_button, "ask_to_exit"))
	%border_button.button_down.connect(_do_action.bind(%border_progress))
	%border_button.button_up.connect(_on_button_released.bind(%border_progress))
	%border_button.pressed.connect(class_functions.run_function.bind(%border_button, "borders"))	
	%widescreen_button.button_down.connect(_do_action.bind(%widescreen_progress))
	%widescreen_button.button_up.connect(_on_button_released.bind(%widescreen_progress))
	%widescreen_button.pressed.connect(class_functions.run_function.bind(%widescreen_button, "widescreen"))
	%quick_rewind_button.button_down.connect(_do_action.bind(%quick_rewind_progress))
	%quick_rewind_button.button_up.connect(_on_button_released.bind(%quick_rewind_progress))
	%quick_rewind_button.pressed.connect(class_functions.run_function.bind(%quick_rewind_button, "rewind"))
	
func _on_button_released(progress: ProgressBar) -> void:
	print ("Release " + progress.name)
	is_state_pressed = false
	progress.visible = false
	press_time = 0.0
	progress.value = 0.0
	
func _do_action(progress: ProgressBar) -> void:
	print ("Action " + progress.name)
	match class_functions.button_list:
		class_functions.button_list:
			is_state_pressed = true
			progress.visible = true

func _do_complete(button: Button) ->void:
	#TODO use object for state
	if is_state_pressed:
		match button.name:
			"button_swap_button":
				class_functions.abxy_state = "false"
			"ask_to_exit_button":
				class_functions.ask_to_exit_state = "false"
			"border_button":
				class_functions.border_state = "false"
			"widescreen_button":
				class_functions.widescreen_state = "false"
			"quick_rewind_button":
				class_functions.quick_rewind_state = "false"
	button.toggle_mode = true
