extends Control

func _ready():
	_get_nodes()
	_connect_signals()

func _connect_signals() -> void:
	%sound_button.pressed.connect(sound_off)

func _get_nodes() -> void:
	pass

func sound_off() -> void:
	class_functions.sound_effects = false
