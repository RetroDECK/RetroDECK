extends Control

var content = null
@onready var custom_theme: Theme = get_tree().current_scene.custom_theme
#@onready var button_off = get_node(current_scene.%l1_button)# .current_scene.l1_button
@onready var lbhide: TextureButton = get_tree().current_scene.get_node("%l1_button")
@onready var rbhide: TextureButton = get_tree().current_scene.get_node("%r1_button")
@onready var bios_type:int = get_tree().current_scene.bios_type

func _ready():
	lbhide.visible=false
	rbhide.visible=false
	$".".theme = custom_theme
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
	$Panel/MarginContainer/VBoxContainer/ContentContainer/MarginContainer/RichTextLabel.text=new_display_text
func _on_back_pressed():
	queue_free()
