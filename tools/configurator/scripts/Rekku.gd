extends Control

var rekku_state = false

func _input(event):
	if event.is_action_released("rekku_hide"):
		#self.visible = !self.visible
		if rekku_state == false:
			self.visible = true
			rekku_state = true
			%SplitContainer.split_offset=-300
		elif event.is_action_released("rekku_hide") and rekku_state == true:
			rekku_state = false
			self.visible = false
			%SplitContainer.split_offset=0
