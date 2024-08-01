extends Node

class_name DataHandler

var data_file_path = "res://data.json"
var app_data: AppData

func _ready():
	# Load the data when the scene is ready
	app_data = load_data()

func load_data() -> AppData:
	var file = FileAccess.open(data_file_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parsed_data = json.parse(json_data)
		if parsed_data.error == OK:
			var data_dict = parsed_data.result

			var about_links = {}
			for key in data_dict["about_links"].keys():
				var link_data = data_dict["about_links"][key]
				var link = Link.new()
				link.name = link_data["name"]
				link.url = link_data["url"]
				link.description = link_data["description"]
				about_links[key] = link

			var emulators = {}
			for key in data_dict["emulators"].keys():
				var emulator_data = data_dict["emulators"][key]
				var emulator = Emulator.new()
				emulator.name = emulator_data["name"]
				emulator.description = emulator_data["description"]

				emulator.options = []
				for option_data in emulator_data["options"]:
					var option = EmulatorOption.new()
					option.resettable = option_data["resettable"]
					emulator.options.append(option)

				emulator.properties = []
				for property_data in emulator_data["properties"]:
					var property = EmulatorProperty.new()
					property.standalone = property_data["standalone"]
					property.abxy_button_status = property_data.get("abxy_button", {}).get("status", false)
					emulator.properties.append(property)

				emulators[key] = emulator

			var app_data = AppData.new()
			app_data.about_links = about_links
			app_data.emulators = emulators

			return app_data
		else:
			print("Error parsing JSON")
	else:
		print("Error opening file")
	return null

func save_data(app_data: AppData):
	var file = FileAccess.open(data_file_path, FileAccess.WRITE)
	if file:
		var data_dict = {}
		
		var about_links = {}
		for key in app_data.about_links.keys():
			var link = app_data.about_links[key]
			about_links[key] = {
				"name": link.name,
				"url": link.url,
				"description": link.description
			}
		
		var emulators = {}
		for key in app_data.emulators.keys():
			var emulator = app_data.emulators[key]
			var options = []
			for option in emulator.options:
				options.append({
					"resettable": option.resettable
				})
			
			var properties = []
			for property in emulator.properties:
				properties.append({
					"standalone": property.standalone,
					"abxy_button": {"status": property.abxy_button_status}
				})
			
			emulators[key] = {
				"name": emulator.name,
				"description": emulator.description,
				"options": options,
				"properties": properties
			}
		
		data_dict["about_links"] = about_links
		data_dict["emulators"] = emulators
		
		var json = JSON.new()
		var json_text = json.print(data_dict)
		file.store_string(json_text)
		file.close()
