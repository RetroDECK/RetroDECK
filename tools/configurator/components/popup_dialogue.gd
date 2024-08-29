extends Control

@onready var custom_theme: Theme = get_tree().current_scene.custom_theme
#@onready var button_off = get_node(current_scene.%l1_button)# .current_scene.l1_button
#@onready var lbhide: TextureButton = get_tree().current_scene.get_node("%l1_button")
#@onready var rbhide: TextureButton = get_tree().current_scene.get_node("%r1_button")
var command: String
var parameters: Array

func _ready():
	$".".theme = custom_theme
	#%title_label.text = "FRED"

func _process(delta):
	if Input.is_action_pressed("back_button"):
		get_tree().quit()
		
func set_title(new_title):
	%title_label.text = new_title
	
func set_content(new_content_text):
	%content_rtl.text=new_content_text	
	
func set_ok_command(ok_command):
	command = ok_command

func set_parameters(new_parameters: Array):
	parameters = new_parameters

func _on_cancel_pressed():
	class_functions.log_parameters[2] = class_functions.log_text + "Exited dialogue"
	class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
	get_tree().quit()

func _on_ok_button_pressed() -> void:
	class_functions.log_parameters[2] = class_functions.log_text + "Command to run:- " + command + " " + str(parameters)
	class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)
	var result = class_functions.execute_command(command,parameters , false)
	class_functions.log_parameters[2] = class_functions.log_text + "Exit code: " + str(result["exit_code"])
	%content_rtl.text = result["output"]
	class_functions.execute_command(class_functions.wrapper_command,class_functions.log_parameters, false)

	
	
