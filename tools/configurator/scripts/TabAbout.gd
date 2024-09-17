extends MarginContainer

var rd_web_button:= Button.new()
var rd_changelog_button:= Button.new()
var rd_wiki_button:= Button.new()
var rd_credits_button:= Button.new()
var rd_donate_button:= Button.new()
var rd_contactus_button:= Button.new()
var rd_licenses_button:= Button.new()
var app_data:= AppData.new()
var button_array: Array = [rd_web_button, rd_changelog_button, rd_wiki_button, rd_credits_button, rd_donate_button, rd_contactus_button, rd_licenses_button]
var web_id: Array = ["rd_web", "rd_changelog", "rd_wiki", "rd_credits", "rd_donate", "rd_contactus", "rd_licenses"]

func _ready():
	#tk_about = class_functions.import_csv_data("res://tk_about.txt")
	app_data = data_handler.app_data
	_connect_signals()
	create_buttons()

func _connect_signals() -> void:
	for i in button_array.size():
		button_array[i].pressed.connect(_about_button_pressed.bind(web_id[i], button_array[i]))

func _about_button_pressed(id: String, button: Button) -> void:
	var tmp_txt = button.text
	if class_functions.desktop_mode != "gamescope":
		class_functions.logger("i","Loading website for " + id)
		class_functions.launch_help(button.editor_description)
	else:
		button.text = "Help only in Desktop Mode"
		await class_functions.wait(3.0)
		button.text = tmp_txt

func create_buttons() -> void:
	for i in button_array.size():
		var button = button_array[i]
		%GridContainer.add_child(button)
		var id = web_id[i]
		if id in app_data.about_links:
			var web_data: Link = app_data.about_links[id]
			_setup_button(button, web_data)

func _setup_button(button: Button, web_data: Link) -> void:
	button.text = web_data.name
	button.tooltip_text = web_data.description
	button.icon = ResourceLoader.load(web_data.icon)
	button.editor_description = web_data.url
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
