extends Control


func _input(event):
	if event.is_action_released("rekku_hide"):
		#self.visible = !self.visible
		if class_functions.rekku_state == false:
			self.visible = true
			class_functions.rekku_state = true
			%SplitContainer.split_offset=925
			%pop_rtl.visible = false
		elif event.is_action_released("rekku_hide") and class_functions.rekku_state == true:
			class_functions.rekku_state = false
			self.visible = false
			%SplitContainer.split_offset=1280
