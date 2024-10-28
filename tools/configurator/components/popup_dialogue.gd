extends Control

var command: String
var parameters: Array
@onready var custom_theme: Theme = get_tree().current_scene.custom_theme

func _ready():
	$".".theme = custom_theme
	var args = OS.get_cmdline_args()
	for arg in range(args.size()):
		if args[arg] == "--title" and arg + 1 < args.size():
			%title_label.text = args[arg + 1]
		elif args[arg] == "--content" and arg + 1 < args.size():
			%content_rtl.text = args[arg + 1]
		elif args[arg] == "--command" and arg + 1 < args.size():
			command = args[arg + 1]
		elif args[arg] == "--parameters" and arg + 1 < args.size():
			parameters.append(args[arg + 1])
		elif args[arg] == "--fullscreen" and arg + 1 < args.size():
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)

func _input(event):
	if Input.is_action_pressed("back_button"):
		get_tree().quit()
	
func _on_cancel_pressed():
	class_functions.logger("d", "Exited dialogue")
	get_tree().quit()

func _on_ok_button_pressed() -> void:
	class_functions.logger("d", "Command to run " + command  + " " + str(parameters))
	var result = class_functions.execute_command(command,parameters , false)
	class_functions.logger("d", "Exit code: " + str(result["exit_code"]))
	%content_rtl.text = result["output"]
	#get_tree().quit()
	
