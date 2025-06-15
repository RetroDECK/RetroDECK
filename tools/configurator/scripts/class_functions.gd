class_name ClassFunctions 

extends Control

# Test comment

@onready var main_scene = get_tree().root.get_node("Control")
var log_result: Dictionary
var log_parameters: Array
const globals_sh_file_path: String = "/app/libexec/global.sh"
const wrapper_command: String = "/app/tools/retrodeck_function_wrapper.sh"
const config_file_path = "/var/config/retrodeck/retrodeck.cfg"
const json_file_path = "/var/config/retrodeck/retrodeck.json"
var config_folder_path = "/var/config/"
const esde_file_path = "/var/config/ES-DE/settings/es_settings.xml"
var desktop_mode: String = OS.get_environment("XDG_CURRENT_DESKTOP")
var rd_conf: String
var lockfile: String
var rd_home_path: String
var rd_home_roms_path: String
var saves_folder: String
var states_folder: String
var rd_home_bios_path: String
var rd_log: String
var rd_log_folder: String
var rd_version: String
var gc_version: String
var sound_effects: bool
var volume_effects: int
var title: String
var quick_resume_status: bool
var update_check: bool
var abxy_state: String
var ask_to_exit_state: String
var border_state: String
var widescreen_state: String
var quick_rewind_state: String
var cheevos_state: String
var cheevos_hardcore_state: String
var cheevos_token_state: String
var font_select: int
var font_tab_size: int = 35
var font_size: int = 20
var steam_sync: bool
var locale: String
var button_list: Array = ["button_swap_button", "ask_to_exit_button", "border_button", "widescreen_button", "quick_rewind_button", "reset_retrodeck_button", "reset_all_emulators_button", "cheevos_button", "cheevos_hardcore_button"]
signal update_global_signal
var rekku_state: bool = false
var press_time: float = 0.0
var is_state_pressed: bool = false
var PRESS_DURATION: float = 3.0
var current_button: Button = null
var current_progress: ProgressBar = null
var current_state: String = ""

func _ready():
	read_values_states()

func read_values_states() -> void:
	var config = data_handler.parse_config_to_json(config_file_path)
	data_handler.config_save_json(config, json_file_path)
	#rd_log_folder = config["paths"]["rd_home_logs_path"]
	rd_log_folder = "/var/config/retrodeck/logs"
	rd_log = rd_log_folder + "/retrodeck.log"
	rd_home_path = config["paths"]["rd_home_path"]
	rd_home_roms_path = config["paths"]["rd_home_roms_path"]
	saves_folder = config["paths"]["saves_folder"]
	states_folder = config["paths"]["states_folder"]
	rd_home_bios_path = config["paths"]["rd_home_bios_path"]
	rd_version = config["version"]
	rd_conf = extract_text(globals_sh_file_path, "rd_conf")
	lockfile = extract_text(globals_sh_file_path, "lockfile")
	locale = extract_text(esde_file_path, "esde")
	gc_version = ProjectSettings.get_setting("application/config/version")
	title = "\n   " + rd_version + "\nConfigurator\n    " + gc_version
	quick_resume_status = config["quick_resume"]["retroarch"]
	update_check = config["options"]["update_check"]
	abxy_state = multi_state("abxy_button_swap", abxy_state)
	ask_to_exit_state = multi_state("ask_to_exit", ask_to_exit_state)
	border_state = multi_state("borders", border_state)
	widescreen_state = multi_state("widescreen", widescreen_state)
	quick_rewind_state = multi_state("rewind", quick_rewind_state)
	sound_effects = config["options"]["sound_effects"]
	steam_sync = config["options"]["steam_sync"]
	volume_effects = int(config["options"]["volume_effects"])
	font_select = int(config["options"]["font"])
	cheevos_token_state = str(config["options"]["cheevos_login"])
	cheevos_state = multi_state("cheevos", cheevos_state)
	cheevos_hardcore_state = multi_state("cheevos_hardcore", cheevos_hardcore_state)

func multi_state(section: String, state: String) -> String:
	var config_section:Dictionary = data_handler.get_elements_in_section(config_file_path, section)
	var true_count: int = 0
	var false_count: int = 0
	for value in config_section.values():
		if value == "true":
			true_count += 1
		else:
			false_count += 1
	if true_count == config_section.size():
		state = "true"
	elif false_count == config_section.size():
		state = "false"
	else:
		state = "mixed"
	return state

func logger_bash(log_type: String, log_text: String) -> void:
	var log_header_text = "gdc_"
	log_header_text+=log_text
	log_parameters = ["log", log_type, log_header_text]
	log_result = await run_thread_command(wrapper_command,log_parameters, false)

func logger(log_type: String, log_text: String) -> void:
	var log_dir: DirAccess = DirAccess.open(rd_log)
	var log_file: FileAccess
	var log_header: String = "[GODOT] "
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	var unixtime: float = Time.get_unix_time_from_system()
	var msec: int = (unixtime - floor(unixtime)) * 1000 # finally, real ms! Thanks, monkeyx
	var timestamp: String = "[%d-%02d-%02d %02d:%02d:%02d.%03d]" % [
	datetime.year, datetime.month, datetime.day,
	datetime.hour, datetime.minute, datetime.second, msec] # real ms!!
	var log_line: String = timestamp

	match log_type:
		'w':
			log_line += " [WARNING] " + log_header
			# print("Warning, mate")
		'e':
			log_line += " [ERROR] " + log_header
			# print("Error, mate")
		'i':
			log_line += " [INFO] " + log_header
			# print("Info, mate")
		'd':
			log_line += " [DEBUG] " + log_header
			# print("Debug, mate")
		_:
			log_line += " " + log_header
			print("No idea, mate")
	log_line += log_text
	# print(log_line)

	if not log_dir:
		log_dir = DirAccess.open("res://") #open something valid to create an instance
		print(log_dir.make_dir_recursive(rd_log_folder))
		if log_dir.make_dir_recursive(rd_log_folder) != OK:
			print("Something wrong with log directory - ", rd_log_folder)
			return

	if not FileAccess.open(rd_log, FileAccess.READ):
		log_file = FileAccess.open(rd_log, FileAccess.WRITE_READ) # to create a file if not there
	else:
		log_file = FileAccess.open(rd_log, FileAccess.READ_WRITE) # to not truncate

	if log_file:
		log_file.seek_end()
		log_file.store_line(log_line)
		log_file.close()
	else:
		print("Something wrong with log file - ", rd_log)

func array_to_string(arr: Array) -> String:
	var text: String
	for line in arr:
		text = line.strip_edges() + "\n"
	return text

func wait (seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# TODO This should be looked at again when GoDot 4.3 ships as has new OS.execute_with_pipe	
func execute_command(command: String, parameters: Array, console: bool) -> Dictionary:
	var result = {}
	var output = []
	var exit_code = OS.execute(command, parameters, output, console) ## add if exit == 0 etc
	result["output"] = class_functions.array_to_string(output)
	result["exit_code"] = exit_code
	return result

func run_command_in_thread(command: String, paramaters: Array, console: bool) -> Dictionary:
	var thread = Thread.new()
	thread.start(execute_command.bind(command,paramaters,console))
	while thread.is_alive():
		await get_tree().process_frame
	return thread.wait_to_finish()
	
func run_thread_command(command: String, parameters: Array, console: bool) -> Dictionary:
	log_result = await run_command_in_thread(command, parameters, console)
	return log_result
	
func process_url_image(body) -> Texture:
	var image = Image.new()
	image.load_png_from_buffer(body)
	var texture = ImageTexture.create_from_image(image)
	return texture

func launch_help(url: String) -> void:
	#OS.unset_environment("LD_PRELOAD")
	#OS.set_environment("XDG_CURRENT_DESKTOP", "KDE") 
	#var launch = class_functions.execute_command("xdg-open",[url], false)
	#var launch = class_functions.execute_command("org.mozilla.firefox",[url], false)
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
		logger("e","Failed to open file %s" % file_path)
		return content
	while not file.eof_reached():
		content += file.get_line() + "\n"
	#file.close
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

func environment_data() -> void:
	var env_result = execute_command("printenv",[], true)
	var file = FileAccess.open(OS.get_environment("HOME") + "/sdenv.txt",FileAccess.WRITE)
	if file != null:
		file.store_string(env_result["output"])
	file.close()

func display_json_data() -> void:
	var app_data := AppData.new()
	app_data = data_handler.app_data
	#data_handler.add_emulator()
	#data_handler.modify_emulator_test()
	if app_data:
		#var website_data: Link = app_data.about_links["rd_web"]
		#print (website_data.name,"-",website_data.url,"-",website_data.description,"-",website_data.url)
		##print (app_data.about_links["rd_web"]["name"])
		#var core_data: Core = app_data.cores["gambatte_libetro"]
		#print (core_data.name)
		#for property: CoreProperty in core_data.properties:
			#print("Cheevos: ", property.cheevos)
			#print("Cheevos Hardcore: ", property.cheevos_hardcore)
			#print("Quick Resume: ", property.quick_resume)
			#print("Rewind: ", property.rewind)
			#print("Borders: ", property.borders)
			#print("Widescreen: ", property.widescreen)
			#print("ABXY_button:", property.abxy_button)
		for key in app_data.emulators.keys():
			var emulator = app_data.emulators[key]
			# Display the properties of each emulator
			print("System Name: ", emulator.name)
			#print("Description: ", emulator.description)
			#print("System: ", emulator.systen)
			#print("Help URL: ", emulator.url)
			#print("Properties:")
			for property: EmulatorProperty in emulator.properties:
				#print("Cheevos: ", property.cheevos)
				#print("Borders: ", property.borders)
				print("ABXY_button:", property.abxy_button)
				#print("multi_user_config_dir: ", property.multi_user_config_dir)
		
		for key in app_data.cores.keys():
			var core = app_data.cores[key]
			print("Core Name: ", core.name)
			#print("Description: ", core.description)
			#print("Properties:")
			for property: CoreProperty in core.properties:
				#print("Cheevos: ", property.cheevos)
				#print("Cheevos Hardcore: ", property.cheevos_hardcore)
				#print("Quick Resume: ", property.quick_resume)
				#print("Rewind: ", property.rewind)
				#print("Borders: ", property.borders)
				#print("Widescreen: ", property.widescreen)
				print("ABXY_button:", property.abxy_button)
	else:
		print ("No emulators")	

func slider_function(value: float, slide: HSlider) -> void:
	volume_effects = int(slide.value)
	data_handler.change_cfg_value(config_file_path, "volume_effects", "options", str(slide.value))

func run_function(button: Button, preset: String) -> void:
	if button.button_pressed:
		update_global(button, preset, true)
	else:
		update_global(button, preset, false)

func update_global(button: Button, preset: String, state: bool) -> void:
	#TODO pass state as an object in future version
	var result: Array	
	result.append("make_preset_changes")
	var config_section:Dictionary = data_handler.get_elements_in_section(config_file_path, preset)
	match button.name:
		"quick_resume_button", "retroarch_quick_resume_button":
			quick_resume_status = state
			result.append_array(data_handler.change_cfg_value(config_file_path, "retroarch", preset, str(state)))
			change_global(result, button, str(quick_resume_status))
		"update_notification_button":
			update_check = state
			#result.append("build_preset_config")
			result.append_array(data_handler.change_cfg_value(config_file_path, preset, "options", str(state)))
			#change_global(result, button, str(result))
		"sound_button":
			sound_effects = state
			result.append_array(data_handler.change_cfg_value(config_file_path, preset, "options", str(state)))
			logger("i", "Enabled: %s" % (button.name))
			update_global_signal.emit([button.name])
		"steam_sync_button":
			steam_sync = state
			result.append_array(data_handler.change_cfg_value(config_file_path, preset, "options", str(state)))
			logger("i", "Enabled: %s" % (button.name))
			update_global_signal.emit([button.name])
		"cheevos_connect_button":
			cheevos_token_state = str(state)
			result.append_array(data_handler.change_cfg_value(config_file_path, preset, "options", str(state)))
			logger("i", "Enabled: %s" % (button.name))
			update_global_signal.emit([button.name])
		"button_swap_button":
			if abxy_state != "mixed":
				abxy_state = str(state)
				result.append_array([preset])
				result.append_array([config_section.keys()])
				change_global(result, button, abxy_state)
		"ask_to_exit_button":
			if ask_to_exit_state != "mixed":
				ask_to_exit_state = str(state)
				result.append_array([preset])
				result.append_array([config_section.keys()])
				change_global(result, button, ask_to_exit_state)
		"border_button":
			if border_state != "mixed":
				border_state = str(state)
				#result.append_array(data_handler.change_all_cfg_values(config_file_path, config_section, preset, str(state)))
				result.append_array([preset])
				result.append_array([config_section.keys()])
				change_global(result, button, border_state)
			if widescreen_state == "true" or widescreen_state == "mixed":
				var _button_tmp = main_scene.get_node("%widescreen_button")
				#Remove last array item or tries to append again
				result.clear()
				result.append_array([preset])
				config_section = data_handler.get_elements_in_section(config_file_path, "widescreen")
				widescreen_state = "false"
				result.append_array([config_section.keys()])
				change_global(result, button, widescreen_state)
		"widescreen_button":
			if widescreen_state != "mixed":
				widescreen_state = str(state)
				result.append_array([preset])
				result.append_array([config_section.keys()])
				change_global(result, button, widescreen_state)
			if border_state == "true" or border_state == "mixed":
				var button_tmp = main_scene.get_node("%border_button")
				#Remove last array item or tries to append again
				result.clear()
				result.append_array([preset])
				config_section = data_handler.get_elements_in_section(config_file_path, "borders")
				border_state = "mixed"
				result.append_array([config_section.keys()])
				change_global(result, button_tmp, border_state)
		"quick_rewind_button":
			if quick_rewind_state != "mixed":
				quick_rewind_state = str(state)
				result.append_array([preset])
				result.append_array([config_section.keys()])
				change_global(result, button, quick_rewind_state)
		"cheevos_button":
			if cheevos_state != "mixed":
				cheevos_state = str(state)
				result.append_array([preset])
				result.append_array([config_section.keys()])
				change_global(result, button, cheevos_state)
			#if cheevos_state == "false":
				#cheevos_hardcore_state = "false"
				#result.append_array(data_handler.change_all_cfg_values(config_file_path, config_section, "cheevos_hardcore", class_functions.cheevos_hardcore_state))
				#change_global(result, button, cheevos_hardcore_state)
		"cheevos_hardcore_button":
			if cheevos_hardcore_state != "mixed":
				cheevos_hardcore_state = str(state)
				result.append_array([preset])
				result.append_array([config_section.keys()])
				change_global(result, button, cheevos_hardcore_state)

func change_global(parameters: Array, button: Button, state: String) -> void:
	#print (parameters)
	match parameters[1]:
		"abxy_button_swap", "ask_to_exit", "borders", "widescreen", "rewind", "cheevos", "cheevos_hardcore":
			var command_parameter: Array
			if state == "true":
				parameters[2] =String(",").join(parameters[2])
				command_parameter = [parameters[0],parameters[1],parameters[2]]
			else:
				command_parameter = [parameters[0],parameters[1]]
			logger("i", "Change Global Multi: %s  " % str(command_parameter))
			var result: Dictionary = await run_thread_command(wrapper_command, command_parameter, false)
			#var result = OS.execute_with_pipe(wrapper_command, command_parameter)
			logger("i", "Exit code: %s" % result["exit_code"])
		_:
			logger("i", "Change Global Single: %s" % str(parameters)) 
			var result: Dictionary = await run_thread_command(wrapper_command, parameters, false)
			#var result = OS.execute_with_pipe(wrapper_command, parameter)
			#var result = OS.create_process(wrapper_command, cparameter)
			if result["exit_code"] == 0:
				logger("i", "Exit code: %s" % result["exit_code"])
			else:
				logger("e", "Exit code: %s" % result["exit_code"])
	parameters.append(button)
	parameters.append(state)
	update_global_signal.emit(parameters)

func extract_text(file_path: String, extract: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.ModeFlags.READ)
	var pattern: String
	if file:
		var regex = RegEx.new() 
		if extract != "esde":
			pattern = extract + '="([^"]+)"' 
		else:
			pattern = '<string name="ApplicationLanguage" value="([^"]+)" />'
		regex.compile(pattern)
		while not file.eof_reached():
			var line: String = file.get_line().strip_edges()
			var result: RegExMatch = regex.search(line)
			if result:
				return result.get_string(1)
		file.close()
	else:
		logger("e", "Could not open file: %s" % file_path)
	return ""

func _on_button_released(progress: ProgressBar) -> void:
	is_state_pressed = false
	progress.visible = false
	press_time = 0.0
	progress.value = 0.0
	current_button = null
	current_progress = null
	current_state == null
	
func _do_action(progress: ProgressBar, button: Button, state: String) -> void:
	match [class_functions.button_list]:
		[class_functions.button_list]:
			current_state = state
	current_button = button
	current_progress = progress
	current_progress.visible = true
	is_state_pressed = true

func _do_complete(button: Button) ->void:
	#TODO use object for state
	if is_state_pressed and button == current_button:
		match button.name:
			"button_swap_button":
				class_functions.abxy_state = "false"
			"ask_to_exit_button":
				class_functions.ask_to_exit_state = "false"
			"border_button":
				class_functions.border_state = "false"
			"widescreen_button":
				class_functions.widescreen_state = "false"
			"quick_rewind_button":
				class_functions.quick_rewind_state = "false"
			"cheevos_button":
				class_functions.cheevos_state = "false"
			"cheevos_hardcore_button":
				class_functions.cheevos_hardcore_state = "false"
			"reset_retrodeck_button":
				var dir = DirAccess.open(class_functions.rd_conf.get_base_dir())
				if dir is DirAccess:
					dir.rename(class_functions.rd_conf, class_functions.rd_conf.get_base_dir() + "/retrodeck.bak")
					dir.remove(class_functions.lockfile)
				class_functions.change_global(["prepare_component", "reset", "retrodeck"], button, "")
				button.text = "RESETTING-NOW"
				await class_functions.wait(2.0)
				button.text = "CONFIGURATOR WILL NOW CLOSE"
				await class_functions.wait(1.0)
				get_tree().quit()
			"reset_all_emulators_button":
				var tmp_txt = button.text
				button.text = "RESETTING-NOW"
				class_functions.change_global(["prepare_component", "reset", "all"], button, "")
				await class_functions.wait(2.0)
				button.text = "RESET COMPLETED"
				await class_functions.wait(3.0)
				button.text = tmp_txt
	button.toggle_mode = true

func _hide_show_containers(button: Button, grid_container: GridContainer) -> void:
	match button.name:
		"decorations_button", "systems_button", "system_button", "cheevos_collapse_button", "future_button":
			grid_container.visible = true
			if button.toggle_mode:
				button.toggle_mode=false
				grid_container.visible = false
			else:
				button.toggle_mode=true
