extends Control

func _ready():
	_get_nodes()
	_connect_signals()

func _connect_signals() -> void:
	%sound_button.pressed.connect(sound_off)
	%update_notification_button.pressed.connect(class_functions.run_function.bind(%update_notification_button))

func _get_nodes() -> void:
	pass

func sound_off() -> void:
	class_functions.sound_effects = false
