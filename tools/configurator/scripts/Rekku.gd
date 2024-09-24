extends Control


func _input(event):
	if event.is_action_released("rekku_hide"):
		#self.visible = !self.visible
		if class_functions.rekku_state == false:
			self.visible = true
			class_functions.rekku_state = true
			%SplitContainer.split_offset=925
			%pop_rtl.visible = false
			%TabContainer.set_tab_title(0, "GLOBALS")
			%TabContainer.set_tab_title(1, "SYSTEM")
			%TabContainer.set_tab_title(2, "TOOLS")
			%TabContainer.set_tab_title(3, "SETTINGS")
			%TabContainer.set_tab_title(4, "ABOUT")
		elif event.is_action_released("rekku_hide") and class_functions.rekku_state == true:
			%TabContainer.set_tab_title(0, "  GLOBALS    ")
			%TabContainer.set_tab_title(1, "  SYSTEM     ")
			%TabContainer.set_tab_title(2, "   TOOLS      ")
			%TabContainer.set_tab_title(3, "  SETTINGS   ")
			%TabContainer.set_tab_title(4, "   ABOUT      ")
			class_functions.rekku_state = false
			%pop_rtl.visible = false
			self.visible = false
			%SplitContainer.split_offset=1280
