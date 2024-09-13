extends MarginContainer

var button_swap: Array

func _ready():
	_connect_signals()

func _connect_signals():
	%quick_resume_button.pressed.connect(class_functions.run_function.bind(%quick_resume_button))
