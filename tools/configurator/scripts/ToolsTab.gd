extends Control

@onready var http_request: HTTPRequest = HTTPRequest.new()

func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	#check_internet_connection()
	_connect_signals()
	%backup_user_button.text += " - " + class_functions.rdhome + "/backup"
	
func _connect_signals() -> void:
	%check_conn_button.pressed.connect(check_internet_connection)
	%backup_user_button.pressed.connect(run_function.bind(%backup_user_button))
	
func run_function(button: Button) -> void:
	var tmp_txt = button.text
	class_functions.logger("d","Start User Backup")
	%progress_bar_backup.visible = true
	%backup_user_button.text = "Backup Running"
	var parameters = ["backup_retrodeck_userdata"]
	var run_result = await class_functions.run_thread_command(class_functions.wrapper_command, parameters, true)
	if run_result["exit_code"] == 0:
		%backup_user_button.text = "Backup Complete - " + class_functions.rdhome + "/backup"
		class_functions.logger("d","User Backup Completed")
		await class_functions.wait(3.0)
		%backup_user_button.text = tmp_txt
		%progress_bar_backup.visible = false
	else:
		%backup_user_button.text = "Backup Failed"
		class_functions.logger("e","User Backup Failed. " + run_result["exit_code"])
		%progress_bar_backup.visible = false

func check_internet_connection():
	class_functions.logger("i","Check Internet Connection")
	%check_conn_button.text = "CHECK CONNECTION"
	http_request.request("https://retrodeck.net/")

func _on_request_completed(_result, response_code, _headers, _body):
	var style_box = StyleBoxFlat.new()
	if response_code == 200:
		class_functions.logger("i","Internet Connection Succesful")
		style_box.bg_color = Color(0, 1, 0)
		%check_conn_button.add_theme_stylebox_override("normal", style_box)
		%check_conn_button.text += " - CONNECTED"

	else:
		class_functions.logger("d","Internet Connection Failed")
		style_box.bg_color = Color(1, 0, 0)
		%check_conn_button.add_theme_stylebox_override("normal", style_box)
		%check_conn_button.text += " - NOT CONNECTED: " + str(response_code)
