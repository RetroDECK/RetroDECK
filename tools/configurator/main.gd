extends Control

var bios_type:int
var status_code_label: Label
var wrapper_command: String = "../../tools/retrodeck_function_wrapper.sh"
var log_text = "GD_Configurator: "
var log_parameters: Array = ["log", "i", log_text]
var log_results: Dictionary
var theme_option: OptionButton
signal signal_theme_changed
var custom_theme: Theme = $".".theme
var emu_select_option: OptionButton
var emu_pick_option: OptionButton
var tab_container: TabContainer
var anim_logo: AnimatedSprite2D
var anim_rekku: AnimatedSprite2D
#var data_handler: DataHandler

var app_data = AppData.new()
func _ready():
	_get_nodes()
	_connect_signals()
	_play_main_animations()

	data_handler.add_emaultor()
	
	 # Example test cases for modifying data
	data_handler.modify_link("example_site", "Updated Site", "https://updated-example.com", "Updated description.")

	var new_options = []
	var new_option = EmulatorOption.new()
	new_option.resettable = false
	new_options.append(new_option)

	var new_properties = []
	var new_property = EmulatorProperty.new()
	new_property.standalone = false
	new_property.abxy_button_status = true
	new_properties.append(new_property)

	data_handler.modify_emulator("example_emulator", "Updated Emulator", "Updated description", new_options, new_properties)
	
	app_data = data_handler.load_data()
	if app_data:
		var website_link = app_data.about_links["rd_web"]
		print (website_link.name,"-",website_link.url,"-",website_link.description)
	
	var emulator_list = class_functions.get_text_file_from_system_path("../../tools/configurator.sh","sed -n '/local emulator_list=(/,/)/{s/.*local emulator_list=\\(.*\\)/\\1/; /)/q; p}' ","emulist")
	print (emulator_list)
	var abxy_button_list = class_functions.get_text_file_from_system_path("/var/config/retrodeck/retrodeck.cfg","sed -n '/\\[abxy_button_swap\\]/,/^$/p' ","normal")
	print(abxy_button_list)
	# set current startup tab to match IDE
	tab_container.current_tab = 3
	#add_child(class_functions) # Needed for threaded results Not need autoload?
	var children = findElements(self, "Control")
	for n: Control in children: #iterate the children
		if (n.focus_mode == FOCUS_ALL):
			n.mouse_entered.connect(_on_control_mouse_entered.bind(n)) #grab focus on mouse hover
		if (n.is_class("BaseButton") and n.disabled == true): #if button-like control and disabled
			n.self_modulate.a = 0.5 #make it half transparent
	combine_tkeys()

func _get_nodes() -> void:
	status_code_label = get_node("%status_code_label")
	theme_option = get_node("%theme_optionbutton")
	emu_select_option = get_node("%emu_select_option")
	emu_pick_option = get_node("%emu_pick_option")
	tab_container = get_node("%TabContainer")
	anim_logo = get_node("%logo_animated")
	anim_rekku = get_node("%rekku_animated")

func _connect_signals() -> void:
	#signal_theme_changed.connect(_conf_theme)
	theme_option.item_selected.connect(_conf_theme)
	signal_theme_changed.emit(theme_option.item_selected)
	emu_select_option.item_selected.connect(_emu_select)
	emu_pick_option.item_selected.connect(_emu_pick)
	
func _emu_select(index: int) -> void:
	emu_pick_option.visible = true
	#change to radio button select
	_play_main_animations()
	if (index == 3): # make function and pass start and end
		emu_pick_option.set_item_disabled(1, true)
		emu_pick_option.set_item_disabled(2, true)
	
func _emu_pick(index: int) -> void:
	emu_pick_option.visible = true
	_play_main_animations()

func _play_main_animations() -> void:
	anim_logo.play()
	anim_rekku.play()

func _conf_theme(index: int) -> void: 
	match index:
		1:
			custom_theme = preload("res://assets/themes/default_theme.tres")
		2:
			custom_theme = preload("res://assets/themes/retro_theme.tres")
		3:
			custom_theme = preload("res://assets/themes/modern_theme.tres")
		4:
			custom_theme = preload("res://assets/themes/accesible_theme.tres")
	$".".theme = custom_theme
	_play_main_animations()

func _input(event):
	if event.is_action_pressed("quit"):
		_exit()

func findElements(node: Node, className: String, result: Array = []) -> Array:
	if node.is_class(className):
		result.push_back(node)
	for child in node.get_children():
		result = findElements(child, className, result)
	return result

func _on_control_mouse_entered(control: Node):
	control.grab_focus()

func load_popup(title:String, content_path:String):
	var popup = load("res://components/popup.tscn").instantiate() as Control
	popup.set_title(title)
	popup.set_content(content_path)
	$Background.add_child(popup)

func _on_quickresume_advanced_pressed():
	load_popup("Quick Resume Advanced", "res://components/popups_content/popup_content_test.tscn")

func _on_bios_button_pressed():
	_play_main_animations()
	bios_type = 0
	log_parameters[2] = log_text + "Bios_Check"
	log_results = class_functions.execute_command(wrapper_command, log_parameters, false)
	load_popup("BIOS File Check", "res://components/bios_check/bios_popup_content.tscn")
	status_code_label.text = str(log_results["exit_code"])

func _on_bios_button_expert_pressed():
	_play_main_animations()
	bios_type = 1
	log_parameters[2] = log_text + "Advanced_Bios_Check"
	log_results = class_functions.execute_command(wrapper_command, log_parameters, false)
	load_popup("BIOS File Check", "res://components/bios_check/bios_popup_content.tscn")
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
	combine_tkeys()
	
func combine_tkeys(): #More as a test
	$Background/MarginContainer/TabContainer/TK_SYSTEM/ScrollContainer/VBoxContainer/game_control_container/GridContainer/cheats.text = tr("TK_CHEATS") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_GRAPHICS/ScrollContainer/VBoxContainer/decorations_container/GridContainer/shaders.text = tr("TK_SHADERS") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_GRAPHICS/ScrollContainer/VBoxContainer/extra_container/GridContainer/tate_mode.text = tr("TK_TATE") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_CONTROLS/ScrollContainer/VBoxContainer/controls_container/hotkey_sound.text = tr("TK_HOTKEYSOUND") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_NETWORK/ScrollContainer/VBoxContainer/cheevos_container/cheevos_advanced_container/cheevos_hardcore.text = tr("TK_CHEEVOSHARDCORE") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_NETWORK/ScrollContainer/VBoxContainer/data_mng_container/saves_sync.text = tr("TK_SAVESSYNC") + " " + tr("TK_SOON")
	$Background/MarginContainer/TabContainer/TK_CONFIGURATOR/ScrollContainer/VBoxContainer/system_container/easter_eggs.text = tr("TK_EASTEREGGS") + " " + tr("TK_SOON")
