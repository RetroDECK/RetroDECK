extends MarginContainer

#var class_functions: ClassFunctions

var website_button: Button
var changelog_button: Button
var wiki_button: Button
var credits_button: Button
var donate_button: Button
var contactus_button: Button
var licenses_button: Button
var tk_about: Dictionary
signal signal_theme_changed

func _ready():
	#class_functions = ClassFunctions.new()
	#tk_about = class_functions._import_data_lists("res://tk_about.txt")
	
	tk_about = class_functions.import_csv_data("tk_about.txt")
	_get_nodes()
	_connect_signals()
	
	for key in tk_about.keys():
		#print("ID: " + key)
		#print("URL: " + entry["URL"])
		#print("Description: " + entry["Description"])
		var entry = tk_about[key]
		match key:
			"rd_web":
				%website_button.tooltip_text = entry["Description"]
				%website_button.editor_description = entry["URL"] # hackish?
			"rd_changelog":
				%changelog_button.tooltip_text = entry["Description"]
				%changelog_button.editor_description = entry["URL"]
			"rd_wiki":
				%wiki_button.tooltip_text = entry["Description"]
				%wiki_button.editor_description = entry["URL"]
			"rd_credits":
				%credits_button.tooltip_text = entry["Description"]
				%credits_button.editor_description = entry["URL"]
			"rd_donate":
				%donate_button.tooltip_text = entry["Description"]
				%donate_button.editor_description = entry["URL"]
			"rd_contactus":
				%contactus_button.tooltip_text = entry["Description"]
				%contactus_button.editor_description = entry["URL"]
			"rd_licenses":
				%licenses_button.tooltip_text = entry["Description"]
				%licenses_button.editor_description = entry["URL"]


func _get_nodes() -> void:
	website_button = get_node("%website_button")
	changelog_button = get_node("%changelog_button")
	wiki_button = get_node("%wiki_button")
	credits_button = get_node("%credits_button")
	donate_button = get_node("%donate_button")
	contactus_button = get_node("%contactus_button")
	licenses_button = get_node("%licenses_button")


func _connect_signals() -> void:
	website_button.pressed.connect(_about_button_pressed.bind("rd_web"))
	changelog_button.pressed.connect(_about_button_pressed.bind("rd_changelog"))
	wiki_button.pressed.connect(_about_button_pressed.bind("rd_wiki"))
	credits_button.pressed.connect(_about_button_pressed.bind("rd_credits"))
	donate_button.pressed.connect(_about_button_pressed.bind("rd_donate"))
	contactus_button.pressed.connect(_about_button_pressed.bind("rd_contactus"))
	licenses_button.pressed.connect(_about_button_pressed.bind("rd_licenses"))
	
func _about_button_pressed(id: String) -> void:
	var entry: Dictionary 
	match id:
		"rd_web":
			entry = tk_about[id] 
			OS.shell_open(%website_button.editor_description)
		"rd_changelog":
			entry = tk_about[id]
			OS.shell_open(%changelog_button.editor_description)
		"rd_wiki":
			entry = tk_about[id]
			OS.shell_open(%wiki_button.editor_description)
		"rd_credits":
			entry = tk_about[id]
			OS.shell_open(%credits_button.editor_description)
		"rd_donate":
			entry = tk_about[id]
			OS.shell_open(%donate_button.editor_description)
		"rd_contactus":
			entry = tk_about[id]
			OS.shell_open(%contactus_button.editor_description)
		"rd_licenses":
			entry = tk_about[id]
			OS.shell_open(%licenses_button.editor_description)
		_:
			print ("ID not found")
