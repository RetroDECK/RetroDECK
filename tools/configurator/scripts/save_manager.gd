extends Node

var json: JSON = JSON.new()
#var path: String = "res://data.json"
var path: String = "res://data_list.json"

var data = {}

func write_json(content):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json.stringify(content))
	file.close()
	file = null
	
func read_json():
	var file = FileAccess.open(path, FileAccess.READ)
	var content = json.parse_string(file.get_as_text())
	if data is Dictionary:
		return content
	else:
		print ("Error")

func create_new_json_file():
	var file = FileAccess.open("res://test.json",FileAccess.READ)
	var content = json.parse_string(file.get_as_text())
	data = content
	write_json(content)
	
func _ready ():
	data = read_json()
