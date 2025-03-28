extends Control

@onready var bios_type:int
var custom_theme: Theme
var log_option: OptionButton
var tab_container: TabContainer
var anim_logo: AnimatedSprite2D
var a_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0042.png")
var b_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0043.png")
var l1_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0797.png")
var r1_button_texture: Texture2D = load("res://assets/icons/kenney_input-prompts-pixel-16/Tiles/tile_0798.png")
var style_box_original: StyleBox = preload("res://assets/themes/default_theme.tres::StyleBoxFlat_0ahfc")
var font_size: int = 20

func _ready():	
	_get_nodes()
	_connect_signals()
	_play_main_animations()
	_set_up_globals([])
	custom_theme = get_tree().current_scene.custom_theme
	$".".theme = custom_theme
	if class_functions.locale == "automatic":
		%locale_option.selected = class_functions.map_locale_id(OS.get_locale_language())
	%rd_title.text += class_functions.title
	class_functions.logger("i","Started Godot configurator")
	#class_functions.display_json_data()
	# set current startup tab to match IDE	
	tab_container.current_tab = 0
	#add_child(class_functions) # Needed for threaded results Not need autoload?
	var children = findElements(self, "Control")
	for n: Control in children: #iterate the children
		if (n.focus_mode == FOCUS_ALL):
			n.mouse_entered.connect(_on_control_mouse_entered.bind(n)) #grab focus on mouse hover
		#if (n.is_class("BaseButton") and n.disabled == true): #if button-like control and disabled
			#n.self_modulate.a = 0.5 #make it half transparent
	#combine_tkeys()
	change_font(class_functions.font_select)
	
func _input(event):
	if Input.is_action_pressed("quit1") and Input.is_action_pressed("quit2"):
		_exit()
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

func _exit():
	class_functions.logger("i","Exited Godot configurator")
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _get_nodes() -> void:
	tab_container = get_node("%TabContainer")
	anim_logo = get_node("%logo_animated")
	log_option = get_node("%logs_button")

func _connect_signals() -> void:
	#signal_theme_changed.connect(_conf_theme)
	%font_optionbutton.item_selected.connect(change_font)
	log_option.item_selected.connect(_load_log)
	%borders_button.pressed.connect(_hide_show_buttons.bind(%borders_button,%borders_gridcontainer,%decorations_gridcontainer))
	%button_layout.pressed.connect(_hide_show_buttons.bind(%button_layout,%borders_gridcontainer,%decorations_gridcontainer))
	%decorations_save.pressed.connect(_hide_show_buttons.bind(%decorations_save,%decorations_save.get_parent(),null))
	%decorations_button.pressed.connect(class_functions._hide_show_containers.bind(%decorations_button, %decorations_gridcontainer))
	%systems_button.pressed.connect(class_functions._hide_show_containers.bind(%systems_button, %systems_gridcontainer))

	class_functions.update_global_signal.connect(_set_up_globals)

func _load_log(index: int) -> void:
	var log_content:String
	match index:
		1: 
			class_functions.logger("i","Loading RetroDeck log")
			log_content = class_functions.import_text_file(class_functions.rd_log_folder +"/retrodeck.log")
			load_popup("RetroDeck Log", "res://components/popup.tscn", log_content)
		2:
			class_functions.logger("i","Loading ES-DE log")
			log_content = class_functions.import_text_file(class_functions.rd_log_folder +"/ES-DE/es_log.txt")
			load_popup("ES-DE Log", "res://components/popup.tscn",log_content)
		3: 
			class_functions.logger("i","Loading RetroArch log")
			log_content = class_functions.import_text_file(class_functions.rd_log_folder +"/retroarch/logs/log.txt")
			load_popup("Retroarch Log", "res://components/popup.tscn",log_content)

func _play_main_animations() -> void:
	anim_logo.play()


# TODO Pass GridContainer(might need 2?) as above
# TODO load existing settings or default to enable all
func _hide_show_buttons(button: Button, buttons_gridcontainer: GridContainer, hidden_gridcontainer: GridContainer) -> void:
	match button.name:
		"borders_button", "button_layout":
			buttons_gridcontainer.visible = true
			if button.toggle_mode == false:
				for i in range(buttons_gridcontainer.get_child_count()):
					var child = buttons_gridcontainer.get_child(i)        
					child.button_pressed=true
				for i in range(hidden_gridcontainer.get_child_count()):
					var child = hidden_gridcontainer.get_child(i)        
					if child is Button and child != button:
						child.visible=false
			elif button.toggle_mode == true and %borders_gridcontainer.visible == true:
				buttons_gridcontainer.visible = false
				#button.toggle_mode = false
				for i in range(hidden_gridcontainer.get_child_count()):
					var child = hidden_gridcontainer.get_child(i)        
					if child is Button:
						child.visible=true
						child.toggle_mode = false
			button.toggle_mode = true

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

func _on_bios_button_pressed():
	_play_main_animations()
	bios_type = 1
	class_functions.logger("i","Bios Check")
	load_popup("BIOS File Check", "res://components/bios_check/bios_popup_content.tscn","")
	bios_type = 0
	
func _on_bios_button_expert_pressed():
	_play_main_animations()
	bios_type = 2
	class_functions.logger("i","Advanced Bios Check")
	load_popup("BIOS File Check", "res://components/bios_check/bios_popup_content.tscn","")
	bios_type = 0
	
func _on_exit_button_pressed():
	_play_main_animations()
	_exit()

#func _on_locale_selected(index):
	#match index:
		#0:
			#TranslationServer.set_locale("en")
		#_:
			#TranslationServer.set_locale("en")
	#combine_tkeys()

#func combine_tkeys(): #More as a test
	#pass
	#%cheats.text = tr("TK_CHEATS") + " " + tr("TK_SOON") # switched to access as a unique name as easier to refactor
	#$Background/MarginContainer/TabContainer/TK_SYSTEM/ScrollContainer/VBoxContainer/HBoxContainer/GridContainer/cheats.text = tr("TK_CHEATS") + " " + tr("TK_SOON")
	#%tate_mode.text = tr("TK_TATE") + " " + tr("TK_SOON")
	#%hotkey_sound.text = tr("TK_HOTKEYSOUND") + " " + tr("TK_SOON")
	#$Background/MarginContainer/TabContainer/TK_NETWORK/ScrollContainer/VBoxContainer/cheevos_container/cheevos_advanced_container/cheevos_hardcore.text = tr("TK_CHEEVOSHARDCORE") + " " + tr("TK_SOON")
	#$Background/MarginContainer/TabContainer/TK_NETWORK/ScrollContainer/VBoxContainer/data_mng_container/saves_sync.text = tr("TK_SAVESSYNC") + " " + tr("TK_SOON")
	#$Background/MarginContainer/TabContainer/TK_CONFIGURATOR/ScrollContainer/VBoxContainer/system_container/easter_eggs.text = tr("TK_EASTEREGGS") + " " + tr("TK_SOON")

func _set_up_globals(state: Array) -> void:
	#TODO on initial run pass array date?
	#print (state)
	%update_notification_button.button_pressed = class_functions.update_check
	%quick_resume_button.button_pressed = class_functions.quick_resume_status
	%retroarch_quick_resume_button.button_pressed = class_functions.quick_resume_status
	%sound_button.button_pressed = class_functions.sound_effects
	%volume_effects_slider.visible = class_functions.sound_effects
	%steam_sync_button.button_pressed = class_functions.steam_sync
	mixed_mode(%button_swap_button, class_functions.abxy_state)
	mixed_mode(%ask_to_exit_button, class_functions.ask_to_exit_state)
	mixed_mode(%border_button, class_functions.border_state)
	mixed_mode(%widescreen_button, class_functions.widescreen_state)
	mixed_mode(%quick_rewind_button, class_functions.quick_rewind_state)
	mixed_mode(%cheevos_button, class_functions.cheevos_state)
	mixed_mode(%cheevos_hardcore_button, class_functions.cheevos_hardcore_state)
	#if class_functions.cheevos_state == "true":
		#%cheevos_enabled_container.visible = true
	#elif class_functions.cheevos_state == "false":
		#%cheevos_enabled_container.visible = false

func mixed_mode (button: Button, state: String) -> void:
	match [class_functions.button_list]:
		[class_functions.button_list]:
			if state == "true":
				button.button_pressed = true
				button.add_theme_stylebox_override("normal", style_box_original)
			elif state == "false":
				button.button_pressed = false
				button.add_theme_stylebox_override("normal", style_box_original)
			elif state == "mixed":
				mixed_status(button)

func mixed_status (button: Button) -> void:
	button.button_pressed = false
	button.toggle_mode = false
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.941, 0.502, 0, 1)
	style_box.border_color = Color(0.102, 0.624, 1, 1)
	style_box.border_blend = true
	style_box.corner_radius_top_left = 25
	style_box.corner_radius_top_right = 25
	style_box.corner_radius_bottom_right = 25
	style_box.corner_radius_bottom_left = 25
	style_box.border_width_left = 15
	style_box.border_width_top = 15
	style_box.border_width_right = 15
	style_box.border_width_bottom = 15
	button.add_theme_stylebox_override("normal", style_box)

func change_font(index: int) -> void:
	var font_file: FontFile
	match index:
		1:
			font_file = load("res://assets/fonts/munro/munro.ttf")
			%TabContainer.add_theme_font_size_override("font_size", class_functions.font_tab_size)
			font_size = 25
		2:
			font_file = load("res://assets/fonts/akrobat/Akrobat-Regular.otf")
			%TabContainer.add_theme_font_size_override("font_size", class_functions.font_tab_size)
			font_size = 25
		3:
			font_file = load("res://assets/fonts/OpenDyslexic3/OpenDyslexic3-Regular.ttf")
			%TabContainer.add_theme_font_size_override("font_size", 15)
			font_size = 16
	custom_theme = load("res://assets/themes/default_theme.tres")
	custom_theme.set_font("font", "Control", font_file)
	custom_theme.default_font_size = font_size
	$".".theme = custom_theme
	data_handler.change_cfg_value(class_functions.config_file_path, "font", "options", str(index))
