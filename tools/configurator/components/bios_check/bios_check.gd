extends Control

var file := FileAccess
var bios_tempfile : String
var BIOS_COLUMNS_BASIC := ["BIOS File Name", "System", "Found", "Hash Match", "Description"]
var BIOS_COLUMNS_EXPERT := ["BIOS File Name", "System", "Found", "Hash Match", "Description", "Subdirectory", "Hash"]
@onready var bios_type:int = get_tree().current_scene.bios_type

func _ready():
	#Check if XDG_RUNTIME_DIR is set and choose temp file location
	if OS.has_environment("XDG_RUNTIME_DIR"):
		bios_tempfile = OS.get_environment("XDG_RUNTIME_DIR") + "/godot_temp/godot_bios_files_checked.tmp"
	else:
		bios_tempfile = "/var/config/retrodeck/godot_temp/godot_bios_files_checked.tmp"
	
	var table := $Table
	
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
		OS.execute("/app/tools/retrodeck_function_wrapper.sh",["check_bios_files", "basic"])
	else: #Assume advanced BIOS button pressed
		OS.execute("/app/tools/retrodeck_function_wrapper.sh",["check_bios_files"])
	
	if file.file_exists(bios_tempfile): #File to be removed after script is done
		var bios_list := file.open(bios_tempfile, FileAccess.READ)
		var bios_line := []
		while ! bios_list.eof_reached():
			bios_line = bios_list.get_csv_line("^")
			var table_line: TreeItem = table.create_item(root)
			for i in bios_line.size():
				table_line.set_text(i, bios_line[i])
				if table_line.get_index() % 2 == 1:
					table_line.set_custom_bg_color(i,Color(0.23, 0.54, 0, 1),false)
					table_line.set_custom_color(i,Color(1,1,1,1))
