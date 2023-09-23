extends Button

func _ready():
	self.pressed.connect(self._button_pressed)

func _button_pressed():
	var output = []
#	var exit_code = OS.execute("ls", ["-l", "/"], output, true)
	var exit_code = OS.execute("bash", ["touch_external.sh"], output)
	print("exit code: ", exit_code)
	print("output: ",
	 output)
