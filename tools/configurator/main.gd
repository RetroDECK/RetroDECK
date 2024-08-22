#todo
# add cores as class/ Like eumlator but one level lower

extends Control

var bios_type:int
var status_code_label: Label
var wrapper_command: String = "../../tools/retrodeck_function_wrapper.sh"
var log_text = "gdc_"
var log_parameters: Array = ["log", "i", log_text]
var log_results: Dictionary
var theme_option: OptionButton
#signal signal_theme_changed
var custom_theme: Theme = $".".theme
var log_option: OptionButton
var tab_container: TabContainer
var anim_logo: AnimatedSprite2D
var rd_logs: String
var rd_version: String
var gc_version: String
var l1_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0797.png")
var r1_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0798.png")
var a_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0042.png")
var b_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0043.png")

var app_data := AppData.new()
func _ready():
	_get_nodes()
	_connect_signals()
	_play_main_animations()
	%locale_option.selected = class_functions.map_locale_id(OS.get_locale_language())
	app_data = data_handler.app_data
	#data_handler.add_emulator()
	#data_handler.modify_emulator_test()
	if app_data:
		var website_data: Link = app_data.about_links["rd_web"]
		print (website_data.name,"-",website_data.url,"-",website_data.description,"-",website_data.url)
		#print (app_data.about_links["rd_web"]["name"])
		
		for key in app_data.emulators.keys():
			var emulator = app_data.emulators[key]
			# Display the properties of each emulator
			print("Emulator Name: ", emulator.name)
			print("Description: ", emulator.description)
			print("Properties:")
			# Iterate over properties and show each one
			for property: EmulatorProperty in emulator.properties:
				print("Cheevos: ", property.cheevos)
				print("ABXY_button:", property.abxy_button)
				print("multi_user_config_dir: ", property.multi_user_config_dir)		
	else:
		print ("No emulators")

	var config_file_path = "/var/config/retrodeck/retrodeck.cfg"
	var json_file_path = "/var/config/retrodeck/retrodeck.json"
	var config = data_handler.parse_config_to_json(config_file_path)
	data_handler.config_save_json(config, json_file_path)
	rd_logs = config["paths"]["logs_folder"]
	rd_version = config["version"]
	gc_version = ProjectSettings.get_setting("application/config/version")
	%rd_title.text+= "\n   " + rd_version + "\nConfigurator\n    " + gc_version
	
	#var log_file = class_functions.import_text_file(rd_logs +"/retrodeck.log")
	#for id in config.paths:
	#	var path_data = config.paths[id]
	#	print (id)

	# set current startup tab to match IDE	
	tab_container.current_tab = 0
	#add_child(class_functions) # Needed for threaded results Not need autoload?
	var children = findElements(self, "Control")
	for n: Control in children: #iterate the children
		if (n.focus_mode == FOCUS_ALL):
			n.mouse_entered.connect(_on_control_mouse_entered.bind(n)) #grab focus on mouse hover
		if (n.is_class("BaseButton") and n.disabled == true): #if button-like control and disabled
			n.self_modulate.a = 0.5 #make it half transparent
	combine_tkeys()

func _input(event):
	if Input.is_action_pressed("quit1") and Input.is_action_pressed("quit2"):
		get_tree().quit()
	if Input.is_action_pressed("next_tab"):
		%r1_button.texture_normal = %r1_button.texture_pressed
	elif Input.is_action_pressed("previous_tab"):
		%l1_button.texture_normal = %l1_button.texture_pressed
	elif Input.is_action_pressed("back_button"):
		%b_button.texture_normal = %b_button.texture_pressed
	elif Input.is_action_pressed("action_button"):
		%a_button.texture_normal = %a_button.texture_pressed
	else:
		%r1_button.texture_normal = r1_button_texture
		%l1_button.texture_normal = l1_button_texture
		%a_button.texture_normal = a_button_texture
		%b_button.texture_normal = b_button_texture
	if event.is_action_pressed("quit"):
		_exit()

func _get_nodes() -> void:
	status_code_label = get_node("%status_code_label")
	theme_option = get_node("%theme_optionbutton")
	tab_container = get_node("%TabContainer")
	anim_logo = get_node("%logo_animated")
	log_option = get_node("%logs_button")
	
func _connect_signals() -> void:
	#signal_theme_changed.connect(_conf_theme)
	theme_option.item_selected.connect(_conf_theme)
	#signal_theme_changed.emit(theme_option.item_selected)
	log_option.item_selected.connect(_load_log)
	%borders_button.pressed.connect(_hide_show)
	%save_button.pressed.connect(_hide_show.bind(%save_button))
	
func _load_log(index: int) -> void:
	var log_content:String
	match index:
		1: 
			log_content = class_functions.import_text_file(rd_logs +"/retrodeck.log")
			load_popup("RetroDeck Log", "res://components/logs_view/logs_popup_content.tscn", log_content)
		2:
			log_content = class_functions.import_text_file(rd_logs +"/ES-DE/es_log.txt")
			load_popup("ES-DE Log", "res://components/logs_view/logs_popup_content.tscn",log_content)
		3: 
			log_content = class_functions.import_text_file(rd_logs +"/retroarch/logs/log.txt")
			load_popup("Retroarch Log", "res://components/logs_view/logs_popup_content.tscn",log_content)	

func _play_main_animations() -> void:
	anim_logo.play()
	
func _hide_show(button: Button):
	if %borders_button.button_pressed:
		%borders_grid_container.visible = true
		for i in range(%borders_grid_container.get_child_count()):
			var child = %borders_grid_container.get_child(i)        
			if child is Button:
				child.button_pressed=true
		for i in range(%graphics_grid_container.get_child_count()):
			var child = %graphics_grid_container.get_child(i)        
			if child is Button and child != %borders_button:
				child.visible=false
		%save_button.visible=true
	elif !%borders_button.button_pressed:
		%borders_grid_container.visible = false
		for i in range(%graphics_grid_container.get_child_count()):
			var child = %graphics_grid_container.get_child(i)        
			if child is Button:
				child.visible=true
		%save_button.visible=false

func _conf_theme(index: int) -> void: 
	print (index)
	match index:
		1:
			custom_theme = preload("res://res/pixel_ui_theme/RetroDECKTheme.tres")
		2:
			custom_theme = preload("res://assets/themes/retro_theme.tres")
		3:
			custom_theme = preload("res://assets/themes/modern_theme.tres")
		4:
			custom_theme = preload("res://assets/themes/accesible_theme.tres")
	$".".theme = custom_theme
	_play_main_animations()

func findElements(node: Node, className: String, result: Array = []) -> Array:
	if node.is_class(className):
		result.push_back(node)
	for child in node.get_children():
		result = findElements(child, className, result)
	return result

func _on_control_mouse_entered(control: Node):
	control.grab_focus()

func load_popup(title:String, content_path:String, display_text: String):
	var popup = load("res://components/popup.tscn").instantiate() as Control
	popup.set_title(title)
	popup.set_content(content_path)
	popup.set_display_text(display_text)
	$Background.add_child(popup)

func _on_quickresume_advanced_pressed():
	load_popup("Quick Resume Advanced", "res://components/popups_content/popup_content_test.tscn","")

func _on_bios_button_pressed():
	_play_main_animations()
	bios_type = 0
	log_parameters[2] = log_text + "Bios_Check"
	log_results = class_functions.execute_command(wrapper_command, log_parameters, false)
	load_popup("BIOS File Check", "res://components/bios_check/bios_popup_content.tscn","")
	status_code_label.text = str(log_results["exit_code"])

func _on_bios_button_expert_pressed():
	_play_main_animations()
	bios_type = 1
	log_parameters[2] = log_text + "Advanced_Bios_Check"
	log_results = class_functions.execute_command(wrapper_command, log_parameters, false)
	load_popup("BIOS File Check", "res://components/bios_check/bios_popup_content.tscn","")
	status_code_label.text = str(log_results["exit_code"])

func _on_exit_button_pressed():
	_play_main_animations()
	log_parameters[2] = log_text + "Exited"
	log_results = class_functions.execute_command(wrapper_command, log_parameters, false)
	_exit()

func _exit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_locale_selected(index):
	match index:
		0:
			TranslationServer.set_locale("en")
		_:
			TranslationServer.set_locale("en")
	combine_tkeys()

"""			
		1:
			TranslationServer.set_locale("it")
		2:
			TranslationServer.set_locale("de")
		3:
			TranslationServer.set_locale("sv")
		4:
			TranslationServer.set_locale("ua")
		5:
			TranslationServer.set_locale("ja")
		6:
			TranslationServer.set_locale("zh")
"""

	
func combine_tkeys(): #More as a test
	%cheats.text = tr("TK_CHEATS") + " " + tr("TK_SOON") # switched to access as a unique name as easier to refactor
	#$Background/MarginContainer/TabContainer/TK_SYSTEM/ScrollContainer/VBoxContainer/HBoxContainer/GridContainer/cheats.text = tr("TK_CHEATS") + " " + tr("TK_SOON")
	#%tate_mode.text = tr("TK_TATE") + " " + tr("TK_SOON")
	#%hotkey_sound.text = tr("TK_HOTKEYSOUND") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_NETWORK/ScrollContainer/VBoxContainer/cheevos_container/cheevos_advanced_container/cheevos_hardcore.text = tr("TK_CHEEVOSHARDCORE") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_NETWORK/ScrollContainer/VBoxContainer/data_mng_container/saves_sync.text = tr("TK_SAVESSYNC") + " " + tr("TK_SOON")
	#$Background/MarginContainer/TabContainer/TK_CONFIGURATOR/ScrollContainer/VBoxContainer/system_container/easter_eggs.text = tr("TK_EASTEREGGS") + " " + tr("TK_SOON")
