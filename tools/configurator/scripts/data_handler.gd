extends Node

class_name DataHandler

var data_file_path = "../../config/retrodeck/reference_lists/features.json"
var app_data: AppData

func _ready():
	# Load the data when the scene is ready
	app_data = load_base_data()

func load_base_data() -> AppData:
	var file = FileAccess.open(data_file_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parsed_data = json.parse_string(json_data)
		#if parsed_data.error == OK:
		if parsed_data:
			var data_dict = parsed_data

			var about_links = {}
			for key in data_dict["about_links"].keys():
				var link_data = data_dict["about_links"][key]
				var link = Link.new()
				link.name = link_data["name"]
				link.url = link_data["url"]
				link.description = link_data["description"]
				about_links[key] = link

			var emulators = {}
			for key in data_dict["emulator"].keys():
				var emulator_data = data_dict["emulator"][key]
				var emulator = Emulator.new()
				
				emulator.name = emulator_data["name"]
				emulator.description = emulator_data["description"]
				print (emulator.name)
				if emulator_data.has("properties"):
					for property_data in emulator_data["properties"]:
						var property = EmulatorProperty.new()
						property.standalone = property_data.get("standalone", false)
#						property.abxy_button_status = property_data.get("abxy_button", {}).get("status", false)
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

func save_base_data(app_data: AppData):
	var file = FileAccess.open(data_file_path, FileAccess.READ)
	var existing_data = {}
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			existing_data = json.get_data()
		file.close()
	else:
		print("File not found. Creating a new one.")		
		var about_links = {}
		for key in app_data.about_links.keys():
			var link = app_data.about_links[key]
			about_links[key] = {
				"name": link.name,
				"url": link.url,
				"description": link.description
			}
		
	var new_data_dict = {}
	# Convert about_links to a dictionary
	var about_links = {}
	for key in app_data.about_links.keys():
		var link = app_data.about_links[key]
		about_links[key] = {
			"name": link.name,
			"url": link.url,
			"description": link.description
	}

	# Convert emulators to a dictionary
	var emulators = {}
	for key in app_data.emulators.keys():
		var emulator = app_data.emulators[key]
		var properties = []
		for property in emulator.properties:
			properties.append({
				"standalone": property.standalone,
				"abxy_button": {"status": property.abxy_button_status}
		})

		emulators[key] = {
			"name": emulator.name,
			"description": emulator.description,
			"properties": properties
		}

	new_data_dict["about_links"] = about_links
	new_data_dict["emulators"] = emulators

	# Merge existing data with new data
	for key in new_data_dict.keys():
		if existing_data.has(key):
			var existing_dict = existing_data[key]
			var new_dict = new_data_dict[key]

			# Merge dictionaries
			for sub_key in new_dict.keys():
				existing_dict[sub_key] = new_dict[sub_key]
		else:
			existing_data[key] = new_data_dict[key]

	# Serialize the combined data to JSON
	var json_text = JSON.new().stringify(existing_data, "\t")

	# Open the file in append mode and write the new JSON data
	file = FileAccess.open(data_file_path, FileAccess.WRITE)
	file.store_string(json_text)
	file.close()
	print("Data appended successfully")
# Function to modify an existing link
func modify_link(key: String, new_name: String, new_url: String, new_description: String):
	var app_data = load_base_data()
	if app_data and app_data.about_links.has(key):
		var link = app_data.about_links[key]
		link.name = new_name
		link.url = new_url
		link.description = new_description
		app_data.about_links[key] = link
		save_base_data(app_data)
		print("Link modified successfully")
	else:
		print("Link not found")

# Function to modify an existing emulator
func modify_emulator(key: String, new_name: String, new_description: String, new_properties: Array):
	var app_data = load_base_data()
	if app_data and app_data.emulators.has(key):
		var emulator = app_data.emulators[key]
		emulator.name = new_name
		emulator.description = new_description
		
		# Update properties
		emulator.properties.clear()
		for property in new_properties:
			var new_property = EmulatorProperty.new()
			new_property.standalone = property.standalone
			new_property.abxy_button_status = property.abxy_button_status
			emulator.properties.append(new_property)

		app_data.emulators[key] = emulator
		save_base_data(app_data)
		print("Emulator modified successfully")
	else:
		print("Emulator not found")


func add_emulator() -> void:
	var link = Link.new()
	link.name = "Example Site"
	link.url = "https://example.com"
	link.description = "An example description."
	app_data.about_links["example_site"] = link

	var emulator = Emulator.new()
	emulator.name = "Example Emulator"
	emulator.description = "An example emulator."
	var property = EmulatorProperty.new()
	property.standalone = true
	property.abxy_button_status = false
	emulator.properties.append(property)
	app_data.emulators["example_emulator"] = emulator
	data_handler.save_base_data(app_data)
	
func modify_emulator_test() -> void:
	data_handler.modify_link("example_site", "Updated Site", "https://updated-example.com", "Updated description.")


	var new_properties = []
	var new_property = EmulatorProperty.new()
	new_property.standalone = false
	new_property.abxy_button_status = true
	new_properties.append(new_property)

	data_handler.modify_emulator("example_emulator", "Updated Emulator", "Updated description",  new_properties)
	

func parse_config_to_json(file_path: String) -> Dictionary:
	var config = {}
	var current_section = ""

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to open file")
		return config
			
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		
		if line.begins_with("[") and line.ends_with("]"):
			# Start a new section
			current_section = line.substr(1, line.length() - 2)
			config[current_section] = {}
		elif line != "" and not line.begins_with("#"):
			# Add key-value pair to the current section
			var parts = line.split("=")
			if parts.size() == 2:
				var key = parts[0].strip_edges()
				var value = parts[1].strip_edges()
					
				# Convert value to proper type
				if value == "true":
					value = true
				elif value == "false":
					value = false	
					
				if key == "version":
					config[key] = value
				else:
					if current_section == "":
						config[key] = value
					else:
						config[current_section][key] = value
	
	file.close()
	return config
	

func config_save_json(config: Dictionary, json_file_path: String) -> void:
	var json = JSON.new()
	var json_string = json.stringify(config, "\t")

	var file = FileAccess.open(json_file_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_string)
		file.close()
	else:
		print("Failed to open JSON file for writing")
