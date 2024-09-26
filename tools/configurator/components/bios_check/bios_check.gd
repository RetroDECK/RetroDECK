extends Control

var bios_result: Dictionary
var console: bool = false
var BIOS_COLUMNS_BASIC := ["BIOS File Name", "System", "Found", "Hash Match", "Description"]
var BIOS_COLUMNS_EXPERT := ["BIOS File Name", "System", "Found", "Hash Match", "Description", "Subdirectory", "Hash"]
@onready var bios_type:int = get_tree().current_scene.bios_type
@onready var custom_theme: Theme = get_tree().current_scene.custom_theme

func _ready():
	#var font_size = get_theme_font_size("font")
	#custom_theme.default_font_size = 16
	$".".theme = custom_theme
	var table: Tree = %Table
	if bios_type == 1: #Basic BIOS button pressed
		table.columns = BIOS_COLUMNS_BASIC.size()
		for i in BIOS_COLUMNS_BASIC.size():
			table.set_column_title(i, BIOS_COLUMNS_BASIC[i])
	else: #Assume advanced BIOS button pressed
		table.columns = BIOS_COLUMNS_EXPERT.size()
		for i in BIOS_COLUMNS_EXPERT.size():
			table.set_column_title(i, BIOS_COLUMNS_EXPERT[i])
	var root = table.create_item()
	table.hide_root = true
	if bios_type == 1: #Basic BIOS button pressed
		var parameters = ["check_bios_files","basic"]
		bios_result = await class_functions.run_thread_command(class_functions.wrapper_command, parameters, console)
	else: #Assume advanced BIOS button pressed
		var parameters = ["check_bios_files"]
		bios_result = await class_functions.run_thread_command(class_functions.wrapper_command, parameters, console)
	var bios_list = bios_result["output"]
	var bios_lines: Array = bios_list.split("\n")
	for line in bios_lines:
		var bios_line: Array = line.split("^")
		var table_line: TreeItem = table.create_item(root)
		for i in bios_line.size():
			if bios_line.size() >= 5:
				if bios_line[2] == "No":
					table_line.set_custom_bg_color(i,Color(1,0,0,0.15))
				elif bios_line[2] == "Yes":
					table_line.set_custom_bg_color(i,Color(0,1,0,0.15))
				elif bios_line[2] == "Yes" and bios_line[3] == "No":
					table_line.set_custom_bg_color(i,Color(1,0.6,0,0.15))
			table_line.set_text(i, bios_line[i])
			#if table_line.get_index() % 2 == 1:
				#table_line.set_custom_bg_color(i,Color(0.15, 0.15, 0.15, 1),false)
				#table_line.set_custom_color(i,Color(1,1,1,1))
