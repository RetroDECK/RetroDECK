extends Button

var thread: Thread

func _ready():
	self.pressed.connect(self._button_pressed)

func _button_pressed():
	thread = Thread.new()
	thread.start(_execute_bash.bind(["progress_file.sh"])) #Need to bind
	self.disabled = true #To prevent multiple launches
#	thread.wait_to_finish() #Should be done somewhere

func _execute_bash(filename):
	var output := []
	var exit_code := OS.execute("bash", filename, output)
	print(exit_code)
