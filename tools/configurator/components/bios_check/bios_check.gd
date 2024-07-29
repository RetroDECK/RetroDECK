extends Control

var classFunctions: ClassFunctions
var file := FileAccess
var bios_tempfile : String
var command: String = "../../tools/retrodeck_function_wrapper.sh"
var console: bool = false
var BIOS_COLUMNS_BASIC := ["BIOS File Name", "System", "Found", "Hash Match", "Description"]
var BIOS_COLUMNS_EXPERT := ["BIOS File Name", "System", "Found", "Hash Match", "Description", "Subdirectory", "Hash"]
@onready var bios_type:int = get_tree().current_scene.bios_type
@onready var custom_theme: Theme = get_tree().current_scene.custom_theme

func _ready():
	$".".theme = custom_theme
	#Check if XDG_RUNTIME_DIR is set and choose temp file location
	if OS.has_environment("XDG_RUNTIME_DIR"):
		#temporary hack for Tim
		# This uses tempfs system revisit
		bios_tempfile = OS.get_environment("XDG_RUNTIME_DIR") + "/godot_temp/godot_bios_files_checked.tmp"
		#	bios_tempfile = "/var/config/retrodeck/godot/godot_bios_files_checked.tmp"
	else:
		bios_tempfile = "/var/config/retrodeck/godot/godot_bios_files_checked.tmp"

	var table := $Table
	classFunctions = ClassFunctions.new()
	add_child(classFunctions)
	
	if bios_type == 0: #Basic BIOS button pressed
		table.columns = BIOS_COLUMNS_BASIC.size()
		for i in BIOS_COLUMNS_BASIC.size():
			table.set_column_title(i, BIOS_COLUMNS_BASIC[i])
	else: #Assume advanced BIOS button pressed
		table.columns = BIOS_COLUMNS_EXPERT.size()
		for i in BIOS_COLUMNS_EXPERT.size():
			table.set_column_title(i, BIOS_COLUMNS_EXPERT[i])
	
	var root = table.create_item()
	table.hide_root = true

	if bios_type == 0: #Basic BIOS button pressed
		#OS.execute("/app/tools/retrodeck_function_wrapper.sh",["check_bios_files", "basic"])
		#var parameters = ["log", "i", "Configurator: " + "check_bios_files"]
	#	classFunctions.execute_command(command, parameters, false)
		var parameters = ["check_bios_files","basic"]
		#result = classFunctions.execute_command(command, parameters, false)
		#threaded
		await run_thread_command(command, parameters, console)
		
	else: #Assume advanced BIOS button pressed
		var parameters = ["check_bios_files"]
		classFunctions.execute_command(command, parameters, false)
		await run_thread_command(command, parameters, console)
		#OS.execute("/app/tools/retrodeck_function_wrapper.sh",["check_bios_files"])
	
	if file.file_exists(bios_tempfile): #File to be removed after script is done
		var bios_list := file.open(bios_tempfile, FileAccess.READ)
		var bios_line := []
		while ! bios_list.eof_reached():
			bios_line = bios_list.get_csv_line("^")
			var table_line: TreeItem = table.create_item(root)
			for i in bios_line.size():
				table_line.set_text(i, bios_line[i])
				if table_line.get_index() % 2 == 1:
					table_line.set_custom_bg_color(i,Color(0.15, 0.15, 0.15, 1),false)
					table_line.set_custom_color(i,Color(1,1,1,1))

func run_thread_command(command: String, parameters: Array, console: bool) -> void:
	var result = await classFunctions.run_command_in_thread(command, parameters, console)
	if result != null:
		print (result["output"])
		print ("Exit Code: " + str(result["exit_code"]))
