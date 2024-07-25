class_name ClassFunctions extends Control

# This should be looked at again when GoDot 4.3 ships as has new OS.execute_with_pipe

func array_to_string(arr: Array) -> String:
	var text = ""
	for line in arr:
		text += line + "\n"
	return text

func execute_command(command: String, parameters: Array, console: bool) -> Dictionary:
	var result = {}
	var output = []
	var exit_code = OS.execute(command, parameters, output, console)
	result["output"] = array_to_string(output)
	result["exit_code"] = exit_code
	return result

func run_command_in_thread(command: String, paramaters: Array, _console: bool) -> Dictionary:
	var thread = Thread.new()
	thread.start(execute_command.bind(command,paramaters,false))
	while thread.is_alive():
		await get_tree().process_frame
	var result = thread.wait_to_finish()
	thread = null
	return result

func _threaded_command_execution(command: String, parameters: Array, console: bool) -> Dictionary:
	var result = execute_command(command, parameters, console)
	return result

# Make this generic for command, path and naming
func get_text_file_from_system_path(file_path: String, command: String) -> Dictionary:
	var output = []
	command += file_path
	var exit_code = OS.execute("sh", ["-c", command], output)
	if exit_code == 0:  
		var content = array_to_string(output)
		return parse_file_list(content)
	else:
		print("Error reading file: ", exit_code)
		return {}

func parse_file_list(content: String) -> Dictionary:
	var file_dict = {}
	var regex = RegEx.new()
	regex.compile(r'"([^"]+)"\s*"([^"]+)"')
	var matches = regex.search_all(content)
	
	for match in matches:
		var name = match.get_string(1)
		var description = match.get_string(2)
		file_dict[name] = description
	return file_dict

func process_url_image(body) -> Texture:
	var image = Image.new()
	image.load_png_from_buffer(body)
	var texture = ImageTexture.create_from_image(image)
	return texture

func launch_help(url: String) -> void:
	OS.shell_open(url)
