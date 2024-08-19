extends MarginContainer

var rd_web_button := Button.new()
var rd_changelog_button := Button.new()
var wiki_button: Button
var credits_button: Button
var donate_button: Button
var contactus_button: Button
var licenses_button: Button
var app_data := AppData.new()
var bArray :Array = [rd_web_button,rd_changelog_button]
func _ready():
	#tk_about = class_functions.import_csv_data("res://tk_about.txt")
	app_data =  data_handler.app_data
	_get_nodes()
	_connect_signals()
	
	for but in bArray:
		%GridContainer.add_child(but)	
	
	for id in app_data.about_links:
		var web_data: Link = app_data.about_links[id]
		match id:
			"rd_web":
				rd_web_button.text = web_data.name
				rd_web_button.tooltip_text = web_data.description
				rd_web_button.icon = ResourceLoader.load("res://assets/icons/pixelitos/128/internet-web-browser.png")
				rd_web_button.editor_description = web_data.url
			"rd_changelog":
				rd_changelog_button.text = web_data.name
				rd_changelog_button.tooltip_text = web_data.description
				rd_changelog_button.icon = ResourceLoader.load("res://assets/icons/pixelitos/128/internet-web-browser.png")
				rd_changelog_button.editor_description = web_data.url
			"rd_wiki":
				%wiki_button.text = web_data.name
				%wiki_button.tooltip_text = web_data.description
				%wiki_button.editor_description = web_data.url
			"rd_credits":
				%credits_button.text = web_data.name
				%credits_button.tooltip_text = web_data.description
				%credits_button.editor_description = web_data.url
			"rd_donate":
				%donate_button.text = web_data.name
				%donate_button.tooltip_text = web_data.description
				%donate_button.editor_description = web_data.url
			"rd_contactus":
				%contactus_button.text = web_data.name
				%contactus_button.tooltip_text = web_data.description
				%contactus_button.editor_description = web_data.url
			"rd_licenses":
				%licenses_button.text = web_data.name
				%licenses_button.tooltip_text = web_data.description
				%licenses_button.editor_description = web_data.url

func _get_nodes() -> void:
	wiki_button = get_node("%wiki_button")
	credits_button = get_node("%credits_button")
	donate_button = get_node("%donate_button")
	contactus_button = get_node("%contactus_button")
	licenses_button = get_node("%licenses_button")

func _connect_signals() -> void:
	rd_web_button.pressed.connect(_about_button_pressed.bind("rd_web"))
	rd_changelog_button.pressed.connect(_about_button_pressed.bind("rd_changelog"))
	wiki_button.pressed.connect(_about_button_pressed.bind("rd_wiki"))
	credits_button.pressed.connect(_about_button_pressed.bind("rd_credits"))
	donate_button.pressed.connect(_about_button_pressed.bind("rd_donate"))
	contactus_button.pressed.connect(_about_button_pressed.bind("rd_contactus"))
	licenses_button.pressed.connect(_about_button_pressed.bind("rd_licenses"))
	
func _about_button_pressed(id: String) -> void:
	match id:
		"rd_web":
			OS.shell_open(rd_web_button.editor_description)
		"rd_changelog":
			OS.shell_open(rd_changelog_button.editor_description)
		"rd_wiki":
			OS.shell_open(%wiki_button.editor_description)
		"rd_credits":
			OS.shell_open(%credits_button.editor_description)
		"rd_donate":
			OS.shell_open(%donate_button.editor_description)
		"rd_contactus":
			OS.shell_open(%contactus_button.editor_description)
		"rd_licenses":
			OS.shell_open(%licenses_button.editor_description)
		_:
			print ("ID not found")
