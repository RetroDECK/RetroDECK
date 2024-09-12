extends MarginContainer

var app_data := AppData.new()
var button_swap: Array

func _ready():
	app_data = data_handler.app_data
	_connect_signals()
		
	#for emulator in app_data.emulators:
		#var emulator_data: Emulator = app_data.emulators[emulator]
		#if emulator_data.properties:
			#if emulator_data.properties:
				##print (emulator_data.name)
				#for property: EmulatorProperty in emulator_data.properties:
					##print (property.abxy_button)
					#button_swap.append(emulator_data.name)
		##print (button_swap)

func _connect_signals():
	%quick_resume_button.pressed.connect(class_functions.run_function.bind(%quick_resume_button))
