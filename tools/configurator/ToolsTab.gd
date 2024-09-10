extends Control

@onready var http_request: HTTPRequest = HTTPRequest.new()


func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	#check_internet_connection()
	_connect_signals()

func _connect_signals() -> void:
	%check_conn_button.pressed.connect(check_internet_connection)
	#%check_conn_button.text = "YES"
	
func check_internet_connection():
	%check_conn_button.text = "CHECK CONNECTION"
	var error = http_request.request("https://retrodeck.net/") # Change this URL to any reliable one
	if error != OK:
		print("Request failed: ", error)
	else:
		print("Request started.")

func _on_request_completed(result, response_code, headers, body):
	var style_box = StyleBoxFlat.new()
	if response_code == 200:
		style_box.bg_color = Color(0, 1, 0)
		%check_conn_button.add_theme_stylebox_override("normal", style_box)
		%check_conn_button.text += " - CONNECTED"

	else:
		style_box.bg_color = Color(1, 0, 0)
		%check_conn_button.add_theme_stylebox_override("normal", style_box)
		%check_conn_button.text += " - NOT CONNECTED: " + str(response_code)
