extends Control

func _ready():
	_connect_signals()

func _process(delta: float) -> void:
	if class_functions.current_button != null:
		update_progress(delta, class_functions.current_progress)

func update_progress(delta: float, progress: ProgressBar) -> void:
	if class_functions.press_time >= class_functions.PRESS_DURATION:
		class_functions._do_complete(class_functions.current_button)
		class_functions.is_state_pressed = false
		#print ("Progress Bar: %s Button: %s" % [progress.name, current_button.name])
	elif class_functions.is_state_pressed and class_functions.current_state == "mixed":
		class_functions.press_time += delta
		progress.value = class_functions.press_time / class_functions.PRESS_DURATION * 100.0

func _connect_signals():
	%quick_resume_button.pressed.connect(class_functions.run_function.bind(%quick_resume_button, "quick_resume"))
	%button_swap_button.button_down.connect(class_functions._do_action.bind(%button_swap_progress, %button_swap_button, class_functions.abxy_state))
	%button_swap_button.button_up.connect(class_functions._on_button_released.bind(%button_swap_progress))
	%button_swap_button.pressed.connect(class_functions.run_function.bind(%button_swap_button, "abxy_button_swap"))
	%ask_to_exit_button.button_down.connect(class_functions._do_action.bind(%ask_to_exit_progress, %ask_to_exit_button, class_functions.ask_to_exit_state))
	%ask_to_exit_button.button_up.connect(class_functions._on_button_released.bind(%ask_to_exit_progress))
	%ask_to_exit_button.pressed.connect(class_functions.run_function.bind(%ask_to_exit_button, "ask_to_exit"))
	%border_button.button_down.connect(class_functions._do_action.bind(%border_progress, %border_button, class_functions.border_state))
	%border_button.button_up.connect(class_functions._on_button_released.bind(%border_progress))
	%border_button.pressed.connect(class_functions.run_function.bind(%border_button, "borders"))	
	%widescreen_button.button_down.connect(class_functions._do_action.bind(%widescreen_progress, %widescreen_button, class_functions.widescreen_state))
	%widescreen_button.button_up.connect(class_functions._on_button_released.bind(%widescreen_progress))
	%widescreen_button.pressed.connect(class_functions.run_function.bind(%widescreen_button, "widescreen"))
	%quick_rewind_button.button_down.connect(class_functions._do_action.bind(%quick_rewind_progress, %quick_rewind_button, class_functions.quick_rewind_state))
	%quick_rewind_button.button_up.connect(class_functions._on_button_released.bind(%quick_rewind_progress))
	%quick_rewind_button.pressed.connect(class_functions.run_function.bind(%quick_rewind_button, "rewind"))
