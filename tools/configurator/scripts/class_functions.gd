class_name ClassFunctions 

extends Control
var log_text = "gdc_"
var log_parameters: Array
var wrapper_command: String = "../../tools/retrodeck_function_wrapper.sh"
var rd_log: String
var rd_log_folder: String
var rd_version: String
var gc_version: String

func read_cfg() -> String:
	var title: String
	var config_file_path = "/var/config/retrodeck/retrodeck.cfg"
	var json_file_path = "/var/config/retrodeck/retrodeck.json"
	var config = data_handler.parse_config_to_json(config_file_path)
	data_handler.config_save_json(config, json_file_path)
	rd_log_folder = config["paths"]["logs_folder"]
	#rd_log = rd_log_folder + "/retrodeck.log"
	rd_log = "/var/config/retrodeck/logs/retrodeck.log"
	log_parameters = ["log", "i", log_text, rd_log]
	rd_version = config["version"]
	gc_version = ProjectSettings.get_setting("application/config/version")
	title = "\n   " + rd_version + "\nConfigurator\n    " + gc_version
	print ("Make logging a function\nAlso add d,i,e,w: ", rd_log)
	return title

func logger() -> void:
	pass
	
func array_to_string(arr: Array) -> String:
	var text: String
	for line in arr:
		#text += line + "\n"
		text = line.strip_edges() + "\n"
	return text

# TODO This should be looked at again when GoDot 4.3 ships as has new OS.execute_with_pipe	
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
	var content: String = ""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to open file")
		return content
	while not file.eof_reached():
		content += file.get_line() + "\n"
	file.close
	return content

func map_locale_id(current_locale: String) -> int:
	var int_locale: int
	match current_locale:
		"en":
			int_locale = 0
		"it":
			int_locale = 1
		"de":
			int_locale = 2
		"se":
			int_locale = 3
		"uk":
			int_locale = 4
		"jp":
			int_locale = 5
		"cn":
			int_locale = 6
	return int_locale
