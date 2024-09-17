extends MarginContainer

var press_time: float = 0.0
var is_state_pressed: bool = false
var PRESS_DURATION: float = 3.0

func _ready():
	_connect_signals()

func _process(delta: float) -> void:
	update_progress(delta, %button_swap_progress, %button_swap_button, class_functions.abxy_state)
	update_progress(delta, %ask_to_exit_progress, %ask_to_exit_button, class_functions.ask_to_exit_state)
	update_progress(delta, %border_progress, %border_button, class_functions.border_state)
	
func update_progress(delta: float, progress: ProgressBar, button: Button, state: String) -> void:
	if is_state_pressed and state == "mixed":
		press_time += delta
		progress.value = press_time / PRESS_DURATION * 100.0
	if press_time >= PRESS_DURATION:
		_do_complete(button)
		press_time = 0.0
		is_state_pressed = false
		progress.value = 0.0

func _connect_signals():
	%quick_resume_button.pressed.connect(class_functions.run_function.bind(%quick_resume_button, "quick_resume"))
	%widescreen_button.pressed.connect(class_functions.run_function.bind(%widescreen_button, "widescreen"))
	%button_swap_button.button_down.connect(_do_action.bind(%button_swap_button, %button_swap_progress))
	%button_swap_button.button_up.connect(_on_button_released.bind(%button_swap_progress))
	%button_swap_button.pressed.connect(class_functions.run_function.bind(%button_swap_button, "abxy_button_swap"))
	%ask_to_exit_button.button_down.connect(_do_action.bind(%ask_to_exit_button, %ask_to_exit_progress))
	%ask_to_exit_button.button_up.connect(_on_button_released.bind(%ask_to_exit_progress))
	%ask_to_exit_button.pressed.connect(class_functions.run_function.bind(%ask_to_exit_button, "ask_to_exit"))
	%border_button.button_down.connect(_do_action.bind(%border_button, %border_progress))
	%border_button.button_up.connect(_on_button_released.bind(%border_progress))
	%border_button.pressed.connect(class_functions.run_function.bind(%border_button, "borders"))	

func _on_button_released(progress: ProgressBar) -> void:
	is_state_pressed = false
	progress.visible = false
	press_time = 0.0
	progress.value = 0.0
	
func _do_action(button: Button, progress: ProgressBar) -> void:
	match button.name:
		"button_swap_button", "ask_to_exit_button", "border_button":
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
	button.toggle_mode = true
