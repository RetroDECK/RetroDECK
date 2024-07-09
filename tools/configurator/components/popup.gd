extends Control

var content = null

func _ready():
	if (content != null):
		$Panel/MarginContainer/VBoxContainer/ContentContainer/MarginContainer.add_child(content)

func set_content(new_content):
	content = load(new_content).instantiate()

func set_title(new_title):
	$Panel/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Label.text = new_title

func _on_back_pressed():
	queue_free()
