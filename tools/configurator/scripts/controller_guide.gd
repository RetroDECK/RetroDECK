extends PanelContainer

func _process(_delta):
	# TODO hack. Use state machine?
	if %action_gridcontainer.visible == true:
		if Input.is_action_pressed("back_button"):
			%action_gridcontainer.visible = false
			%retroarch_button.grab_focus()
			for i in range(%system_gridcontainer.get_child_count()):
				var child = %system_gridcontainer.get_child(i)        
				if child is Button:
					child.visible=true
					child.toggle_mode = false
