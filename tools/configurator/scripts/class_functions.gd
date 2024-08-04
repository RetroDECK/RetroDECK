class_name ClassFunctions extends Control

# This should be looked at again when GoDot 4.3 ships as has new OS.execute_with_pipe

func array_to_string(arr: Array) -> String:
	var text: String
	for line in arr:
		#text += line + "\n"
		text = line.strip_edges() + "\n"
	return text

func execute_command(command: String, parameters: Array, console: bool) -> Dictionary:
	var result = {}
	var output = []
	var exit_code = OS.execute(command, parameters, output, console) ## add if exit == 0 etc
	result["output"] = array_to_string(output)
	result["exit_code"] = exit_code
	#print (array_to_string(output))
	#print (result["exit_code"])
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

func process_url_image(body) -> Texture:
	var image = Image.new()
	image.load_png_from_buffer(body)
	var texture = ImageTexture.create_from_image(image)
	return texture

func launch_help(url: String) -> void:
	OS.shell_open(url)

func import_csv_data(file_path: String) -> Dictionary:
	# check if file exists
	var data_dict: Dictionary
	var file = FileAccess.open(file_path,FileAccess.READ)
	if file:
		var csv_lines: PackedStringArray = file.get_as_text().strip_edges().split("\n")
		for i in range(1, csv_lines.size()):  # Start from 1 to skip the header
			var line = csv_lines[i]
			var columns = line.split(",")
			if columns.size() >= 3: 
				var id = columns[0]
				var url = columns[1]
				var description = columns[2]
				data_dict[id] = {"URL": url, "Description": description}
		file.close()
	else:
		print ("Could not open file: %s", file_path)

	return data_dict

func _import_data_lists(file_path: String) -> void:
	var tk_about: Dictionary = import_csv_data(file_path)
	
	for key in tk_about.keys():
		var entry = tk_about[key]
		print("ID: " + key)
		print("URL: " + entry["URL"])
		print("Description: " + entry["Description"])
		print("---")

func import_text_file(file_path: String) -> String:
	var content: String
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to open file")
		return content
	while not file.eof_reached():
		content += file.get_line() + "\n"
	file.close
	return content
