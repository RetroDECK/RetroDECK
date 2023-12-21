extends Control

func _ready():
	$MarginContainer/TabContainer/System/ScrollContainer/VBoxContainer/game_control_container/GridContainer/resume.grab_focus() #Required to enable controller focusing

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()
