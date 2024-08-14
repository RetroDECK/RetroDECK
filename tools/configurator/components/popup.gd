extends Control

var content = null
@onready var custom_theme: Theme = get_tree().current_scene.custom_theme

func _ready():
	$".".theme = custom_theme
	if (content != null):
		$Panel/MarginContainer/VBoxContainer/ContentContainer/MarginContainer.add_child(content)

func set_content(new_content):
	content = load(new_content).instantiate()
func set_title(new_title):
	$Panel/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Label.text = new_title
func set_display_text(new_display_text):
	$Panel/MarginContainer/VBoxContainer/ContentContainer/MarginContainer/RichTextLabel.text=new_display_text
func _on_back_pressed():
	queue_free()
