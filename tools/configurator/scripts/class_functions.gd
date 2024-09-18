class_name ClassFunctions 

extends Control
var log_result: Dictionary
var log_parameters: Array
const globals_sh_file_path: String = "/app/libexec/global.sh"
const wrapper_command: String = "/app/tools/retrodeck_function_wrapper.sh"
const config_file_path = "/var/config/retrodeck/retrodeck.cfg"
const json_file_path = "/var/config/retrodeck/retrodeck.json"
var desktop_mode: String = OS.get_environment("XDG_CURRENT_DESKTOP")
var rd_conf: String
var lockfile: String
var rdhome: String
var roms_folder: String
var saves_folder: String
var states_folder: String
var bios_folder: String
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
var font_select: int
enum preset_list {abxy_button_swap, ask_to_exit, borders, widescreen, rewind}
var button_list: Array = ["button_swap_button", "ask_to_exit_button", "border_button", "widescreen_button", "quick_rewind_button"]
signal update_global_signal

func _ready():
	read_values_states()

func read_values_states() -> void:
	var config = data_handler.parse_config_to_json(config_file_path)
	data_handler.config_save_json(config, json_file_path)
	rd_log_folder = config["paths"]["logs_folder"]
	rd_log = rd_log_folder + "/retrodeck.log"
	rdhome = config["paths"]["rdhome"]
	roms_folder = config["paths"]["roms_folder"]
	saves_folder = config["paths"]["saves_folder"]
	states_folder = config["paths"]["states_folder"]
	bios_folder = config["paths"]["bios_folder"]
	rd_version = config["version"]
	rd_conf = extract_goblals(globals_sh_file_path, "rd_conf")
	lockfile = extract_goblals(globals_sh_file_path, "lockfile")
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
	volume_effects = int(config["options"]["volume_effects"])
	font_select = int(config["options"]["font"])

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
		
func logger(log_type: String, log_text: String) -> void:
	# Type of log messages:
	# log d - debug message: maybe in the future we can decide to hide them in main builds or if an option is toggled
	# log i - normal informational message
	# log w - waring: something is not expected but it's not a big deal
	# log e - error: something broke
	var log_header_text = "gdc_"
	log_header_text+=log_text
	log_parameters = ["log", log_type, log_header_text]
	log_result = await run_thread_command(wrapper_command,log_parameters, false)
	#log_result = await run_thread_command("find",["$HOME", "-name", "*.xml","-print"], false)
	#print (log_result["exit_code"])
	#print (log_result["output"])
	
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
	result["output"] = array_to_string(output)
	result["exit_code"] = exit_code
	return result

func run_command_in_thread(command: String, paramaters: Array, _console: bool) -> Dictionary:
	var thread = Thread.new()
	thread.start(execute_command.bind(command,paramaters,false))
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
	var config_section:Dictionary = data_handler.get_elements_in_section(config_file_path, preset)
	match button.name:
		"reset_retrodeck_button":
			var dir = DirAccess.open(rd_conf.get_base_dir())
			if dir is DirAccess:
				dir.rename(rd_conf,rd_conf.get_base_dir() + "/retrodeck.bak")
				dir.remove(lockfile)
			
		"quick_resume_button", "retroarch_quick_resume_button":
			quick_resume_status = state
			result = data_handler.change_cfg_value(config_file_path, "retroarch", preset, str(state))
			change_global(result, "build_preset_config", button, str(quick_resume_status))
		"update_notification_button":
			update_check = state
			result = data_handler.change_cfg_value(config_file_path, preset, "options", str(state))
			change_global(result, "build_preset_config", button, str(result))
		"sound_button":
			sound_effects = state
			result = data_handler.change_cfg_value(config_file_path, preset, "options", str(state))
			logger("i", "Enabled: " % (button.name))
		"button_swap_button":
			if abxy_state != "mixed":
				abxy_state = str(state)
				result = data_handler.change_all_cfg_values(config_file_path, config_section, preset, str(state))
				change_global(result, "build_preset_config", button, abxy_state)
		"ask_to_exit_button":
			if ask_to_exit_state != "mixed":
				ask_to_exit_state = str(state)
				result = data_handler.change_all_cfg_values(config_file_path, config_section, preset, str(state))
				change_global(result, "build_preset_config", button, ask_to_exit_state)
		"border_button":
			if border_state != "mixed":
				border_state = str(state)
				result = data_handler.change_all_cfg_values(config_file_path, config_section, preset, str(state))
				change_global(result, "build_preset_config", button, border_state)
			if widescreen_state == "true" or widescreen_state == "mixed":
				config_section = data_handler.get_elements_in_section(config_file_path, "widescreen")
				widescreen_state = "false"
				result = data_handler.change_all_cfg_values(config_file_path, config_section, "widescreen", widescreen_state)
				change_global(result, "build_preset_config", button, widescreen_state)
		"widescreen_button":
			if widescreen_state != "mixed":
				widescreen_state = str(state)
				result = data_handler.change_all_cfg_values(config_file_path, config_section, preset, str(state))
				change_global(result, "build_preset_config", button, widescreen_state)
			if border_state == "true" or border_state == "mixed":
				config_section = data_handler.get_elements_in_section(config_file_path, "borders")
				border_state = "false"
				result = data_handler.change_all_cfg_values(config_file_path, config_section, "borders", border_state)
				change_global(result, "build_preset_config", button, border_state)
		"quick_rewind_button":
			if quick_rewind_state != "mixed":
				quick_rewind_state = str(state)
				result = data_handler.change_all_cfg_values(config_file_path, config_section, preset, str(state))
				change_global(result, "build_preset_config", button, quick_rewind_state)
				
func change_global(parameters: Array, preset: String, button: Button, state: String) -> void:
	print (parameters)
	match parameters[1]:
		preset_list:
			for system in parameters[0].keys():
				var command_parameter: Array = [preset, system, parameters[1]]
				logger("d", "Change Global: %s System: %s Preset %s " % command_parameter) 
				var result: Dictionary = await run_thread_command(wrapper_command, command_parameter, false)
				logger("d", "Exit code: %s" % result["exit_code"])
		_:
			var command_parameter: Array = [preset, parameters]
			logger("d", "Change Global: %s System: %s" % command_parameter) 
			var result: Dictionary = await run_thread_command(wrapper_command, command_parameter, false)
			logger("d", "Exit code: %s" % result["exit_code"])
	parameters.append(button)
	parameters.append(state)
	update_global_signal.emit(parameters)

func extract_goblals(file_path: String, extract: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.ModeFlags.READ)
	if file:
		var regex := RegEx.new() 
		var pattern := extract + '="([^"]+)"' 
		regex.compile(pattern)
		while not file.eof_reached():
			var line := file.get_line().strip_edges()
			var result := regex.search(line)
			if result:
				return result.get_string(1)
		file.close()
	else:
		logger("e", "Could not open file: %s" % file_path)
	return ""
