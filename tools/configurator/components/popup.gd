extends Control

var content = null
#@onready var button_off = get_node(current_scene.%l1_button)# .current_scene.l1_button
@onready var lbhide: Panel = get_tree().current_scene.get_node("%l1_box")
@onready var rbhide: Panel = get_tree().current_scene.get_node("%r1_box")
@onready var bios_type:int = get_tree().current_scene.bios_type
@onready var custom_theme: Theme = get_tree().current_scene.custom_theme

func _ready():
	$".".theme = custom_theme
	lbhide.visible=false
	rbhide.visible=false
	# TODO this alowes copy and paste from RTB in logs?
	if (content != null and bios_type > 0):
		$Panel/MarginContainer/VBoxContainer/ContentContainer/MarginContainer.add_child(content)
	

func _process(delta):
	if Input.is_action_pressed("back_button"):
		lbhide.visible=true
		rbhide.visible=true
		queue_free()

func set_content(new_content):
	content = load(new_content).instantiate()
func set_title(new_title):
	$Panel/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Label.text = new_title
func set_display_text(new_display_text):
	$Panel/MarginContainer/VBoxContainer/ContentContainer/MarginContainer/LineEdit.text=new_display_text
func _on_back_pressed():
	queue_free()
