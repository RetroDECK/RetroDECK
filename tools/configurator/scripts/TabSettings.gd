extends Control

func _ready():
	_connect_signals()

func _connect_signals() -> void:
	%sound_button.pressed.connect(class_functions.run_function.bind(%sound_button))
	%update_notification_button.pressed.connect(class_functions.run_function.bind(%update_notification_button))
	#%volume_effects_slider.changed.connect(class_functions.slider_function.bind(%volume_effects_slider))
	%volume_effects_slider.drag_ended.connect(class_functions.slider_function.bind(%volume_effects_slider))
