extends Control
var responses: Array

func _ready():
	_connect_signals()
	if class_functions.cheevos_state != "false":
		#%cheevos_label.add_theme_stylebox_override()
		%cheevos_label.add_theme_color_override("font_color", Color(0.941, 0.502, 1, 1))
		%cheevos_label.text = "ALREADY LOGGED IN"
		#%cheevos_connect_button.text = "LOGOUT"
func _connect_signals() -> void:
	%sound_button.pressed.connect(class_functions.run_function.bind(%sound_button, "sound_effects"))
	%update_notification_button.pressed.connect(class_functions.run_function.bind(%update_notification_button, "update_check"))
	%volume_effects_slider.drag_ended.connect(class_functions.slider_function.bind(%volume_effects_slider))
	%cheevos_connect_button.pressed.connect(cheevos.bind(%cheevos_connect_button))
	%cheevos_button.button_down.connect(class_functions._do_action.bind(%cheevos_progress, %cheevos_button, class_functions.cheevos_state))
	%cheevos_button.button_up.connect(class_functions._on_button_released.bind(%cheevos_progress))
	%cheevos_button.pressed.connect(class_functions.run_function.bind(%cheevos_button, "cheevos"))
	%cheevos_hardcore_button.button_down.connect(class_functions._do_action.bind(%cheevos_hardcore_progress, %cheevos_hardcore_button, class_functions.cheevos_hardcore_state))
	%cheevos_hardcore_button.button_up.connect(class_functions._on_button_released.bind(%cheevos_hardcore_progress))
	%cheevos_hardcore_button.pressed.connect(class_functions.run_function.bind(%cheevos_hardcore_button, "cheevos_hardcore"))
	%reset_retrodeck_button.button_down.connect(class_functions._do_action.bind(%reset_retrodeck_progress, %reset_retrodeck_button, "mixed"))
	%reset_retrodeck_button.button_up.connect(class_functions._on_button_released.bind(%reset_retrodeck_progress))	
	%reset_all_emulators_button.button_down.connect(class_functions._do_action.bind(%reset_all_emulators_progress, %reset_all_emulators_button, "mixed"))
	%reset_all_emulators_button.button_up.connect(class_functions._on_button_released.bind(%reset_all_emulators_progress))

func _on_request_completed(_result, response_code, _headers, body) -> Array:
	var response_text = JSON.parse_string(body.get_string_from_utf8())
	var cheevos_token: String = ""
	#print("Response Code: ", response_code)
	#print("Response Body: ", response_text)
	#print ("Response Success: ", response_text.Success)
	#print("Response Token: ", response_text.Token)
	if response_text.Success:
		cheevos_token = response_text.Token
	if response_code == 200:
		responses = [response_code, response_text.Success, cheevos_token]
		return responses
	return responses

func cheevos(button: Button):
	class_functions.logger("d","Attempting RA connection")
	var ra_url = "https://retroachievements.org/dorequest.php?r=login&u="+%cheevos_username.text+"&p="+%cheevos_password.text 
	button.disabled = true
	%cheevos_label.text = "ATTEMPTING LOGIN"
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_request_completed)
	http_request.request(ra_url)
	responses = await wait_to_complete(http_request)
	%cheevos_label.text = "LOGIN SUCCESS = %s" % str(responses[1]).to_upper()
	button.disabled = false

func wait_to_complete(http_request: HTTPRequest) -> Array:
	await http_request.request_completed
	return responses
