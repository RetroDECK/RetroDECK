extends Control

var ra_url = "https://retroachievements.org/dorequest.php?r=login&u=monkeyx&p=9LJX7**mie*9e4"
var cheevos_token: String

func _ready():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	_connect_signals()
	http_request.request_completed.connect(self._on_request_completed)
	http_request.request(ra_url)

func _connect_signals() -> void:
	%sound_button.pressed.connect(class_functions.run_function.bind(%sound_button, "sound_effects"))
	%update_notification_button.pressed.connect(class_functions.run_function.bind(%update_notification_button, "update_check"))
	%volume_effects_slider.drag_ended.connect(class_functions.slider_function.bind(%volume_effects_slider))
	#%cheevos_button.pressed.connect(cheevos.bind(%cheevos_button))
	%cheevos_button.button_down.connect(class_functions._do_action.bind(%cheevos_progress, %cheevos_button, class_functions.cheevos_state))
	%cheevos_button.button_up.connect(class_functions._on_button_released.bind(%cheevos_progress))
	%cheevos_button.pressed.connect(class_functions.run_function.bind(%cheevos_button, "cheevos"))
	%cheevos_hardcore_button.button_down.connect(class_functions._do_action.bind(%cheevos_hardcore_progress, %cheevos_hardcore_button, class_functions.cheevos_hardcore_state))
	%cheevos_hardcore_button.button_up.connect(class_functions._on_button_released.bind(%cheevos_hardcore_progress))
	%cheevos_hardcore_button.pressed.connect(class_functions.run_function.bind(%cheevos_hardcore_button, "cheevos_hardcore"))

func _on_request_completed(_result, response_code, _headers, body):
	var response_text = JSON.parse_string(body.get_string_from_utf8())
	print("Response Code: ", response_code)
	print("Response Body: ", response_text)
	print("Response Token: ", response_text.Token)
	#print (_result,_headers)
	cheevos_token = response_text.Token
	if response_code == 200:
		print("Request successful!")
	else:
		print("Request failed with code: ", response_code)

func cheevos(button: Button):
		set_process_input(false)
		$"../..".visible=false
		await class_functions.run_thread_command(class_functions.wrapper_command,["change_preset_dialog", "cheevos"], false)
		set_process_input(true)
		$"../..".visible=true
