extends Control
var split_max: int = 1280
var split_min: int = 925

func _input(event):
	if event.is_action_released("rekku_hide"):
		#self.visible = !self.visible
		if class_functions.rekku_state == false:
			self.visible = true
			class_functions.rekku_state = true
			for n in range (split_max, split_min,-2):
				await class_functions.wait(0.000000001)
				%SplitContainer.split_offset=n
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
			%pop_rtl.visible = false
			for n in range (split_min, split_max,2):
				await class_functions.wait(0.000000001)
				%SplitContainer.split_offset=n
			class_functions.rekku_state = false
			self.visible = false
