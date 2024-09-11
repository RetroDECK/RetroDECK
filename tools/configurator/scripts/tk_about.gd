extends MarginContainer

var rd_web_button := Button.new()
var rd_changelog_button := Button.new()
var rd_wiki_button := Button.new()
var rd_credits_button := Button.new()
var rd_donate_button := Button.new()
var rd_contactus_button := Button.new()
var rd_licenses_button := Button.new()
var app_data:= AppData.new()
var bArray :Array = [rd_web_button,rd_changelog_button,rd_wiki_button,
rd_credits_button,rd_donate_button,rd_contactus_button,rd_licenses_button]

func _ready():
	#tk_about = class_functions.import_csv_data("res://tk_about.txt")
	app_data = data_handler.app_data
	_connect_signals()
	create_buttons()

func _connect_signals() -> void:
	rd_web_button.pressed.connect(_about_button_pressed.bind("rd_web", rd_web_button))
	rd_changelog_button.pressed.connect(_about_button_pressed.bind("rd_changelog", rd_changelog_button))
	rd_wiki_button.pressed.connect(_about_button_pressed.bind("rd_wiki",rd_wiki_button))
	rd_credits_button.pressed.connect(_about_button_pressed.bind("rd_credits", rd_credits_button))
	rd_donate_button.pressed.connect(_about_button_pressed.bind("rd_donate", rd_donate_button))
	rd_contactus_button.pressed.connect(_about_button_pressed.bind("rd_contactus", rd_contactus_button))
	rd_licenses_button.pressed.connect(_about_button_pressed.bind("rd_licenses", rd_licenses_button))
	
func _about_button_pressed(id: String, button: Button) -> void:
	var tmp_txt = button.text
	match id:
		"rd_web", "rd_changelog", "rd_wiki", "rd_credits", "rd_donate", "rd_contactus", "rd_licenses":
			if class_functions.desktop_mode != "gamescope":
				class_functions.logger("i","Loading website for " + id)
				class_functions.launch_help(button.editor_description)
			else:
				button.text = "Help only in Desktop Mode"
				await class_functions.wait(3.0)
				button.text = tmp_txt
		_:
			class_functions.logger("d","Loading website for " + id)
			print ("Website ID/Link not found")

func create_buttons() -> void:
	for button in bArray:
		%GridContainer.add_child(button)
	for id in app_data.about_links:
		var web_data: Link = app_data.about_links[id]
		match id:
			"rd_web":
				rd_web_button.text = web_data.name
				rd_web_button.tooltip_text = web_data.description
				rd_web_button.icon = ResourceLoader.load(web_data.icon)
				rd_web_button.editor_description = web_data.url
				rd_web_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				rd_web_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			"rd_changelog":
				rd_changelog_button.text = web_data.name
				rd_changelog_button.tooltip_text = web_data.description
				rd_changelog_button.icon = ResourceLoader.load(web_data.icon)
				rd_changelog_button.editor_description = web_data.url
				rd_changelog_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				rd_changelog_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			"rd_wiki":
				rd_wiki_button.text = web_data.name
				rd_wiki_button.tooltip_text = web_data.description
				rd_wiki_button.icon = ResourceLoader.load(web_data.icon)
				rd_wiki_button.editor_description = web_data.url
				rd_wiki_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				rd_wiki_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			"rd_credits":
				rd_credits_button.text = web_data.name
				rd_credits_button.tooltip_text = web_data.description
				rd_credits_button.icon = ResourceLoader.load(web_data.icon)
				rd_credits_button.editor_description = web_data.url
				rd_credits_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				rd_credits_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			"rd_donate":
				rd_donate_button.text = web_data.name
				rd_donate_button.tooltip_text = web_data.description
				rd_donate_button.icon = ResourceLoader.load(web_data.icon)
				rd_donate_button.editor_description = web_data.url
				rd_donate_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				rd_donate_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			"rd_contactus":
				rd_contactus_button.text = web_data.name
				rd_contactus_button.tooltip_text = web_data.description
				rd_contactus_button.icon = ResourceLoader.load(web_data.icon)
				rd_contactus_button.editor_description = web_data.url
				rd_contactus_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				rd_contactus_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			"rd_licenses":
				rd_licenses_button.text = web_data.name
				rd_licenses_button.tooltip_text = web_data.description
				rd_licenses_button.icon = ResourceLoader.load(web_data.icon)
				rd_licenses_button.editor_description = web_data.url
				rd_licenses_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				rd_licenses_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
