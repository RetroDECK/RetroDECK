extends Control

func _input(event):
	if event.is_action_pressed("rekku_hide"):
		self.visible = !self.visible
