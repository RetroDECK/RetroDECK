extends GridContainer

func _ready():
	_connect_signals()

func _connect_signals() -> void:
	%help_button.pressed.connect(_do_action.bind(%help_button))
	%launch_button.pressed.connect(_do_action.bind(%launch_button))

func _do_action(button: Button) -> void:
	match button.name:
		#Make generic find passing button/container
		"help_button":
			class_functions.log_parameters[2] = class_functions.log_text + "Launching RD HELP"
			class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
			class_functions.launch_help("https://retrodeck.readthedocs.io/en/latest/wiki_emulator_guides/retroarch/retroarch-guide/")
		"launch_button":
			class_functions.log_parameters[2] = class_functions.log_text + "Launching RD!"
			class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
			class_functions.execute_command("/home/tim/Applications/RetroArch-Linux-x86_64.AppImage",[], false)
