extends Control

func _input(event):
	if event.is_action_pressed("rekku_hide"):
		self.visible = !self.visible
		%SplitContainer.split_offset=-300

	if Input.is_action_pressed("back_button"):
		%SplitContainer.split_offset=0
		$".".visible=false
		
		
