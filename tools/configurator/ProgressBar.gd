extends ProgressBar

var progress_file := "progress" #File with progress from 0 to 100
var progress_button: Button
var file := FileAccess

var prev_prog: float = 0

func _ready():
	self.value = 0
	progress_button = $"../HBoxContainerProgress/ProgressButton"

func _process(delta):
	if file.file_exists(progress_file): #File to be removed after script is done
		var file := FileAccess.open(progress_file, FileAccess.READ)
		var _progress := float(file.get_as_text())
		if prev_prog != _progress: #To not rewrite every frame
			self.value = _progress
			print("boom", _progress)
			prev_prog = _progress
	else:
		if prev_prog == 100:
			progress_button.disabled = false #Reenable progress button
			prev_prog = 0


func _on_check_button_toggled(button_pressed):
	var _fill_color := Color("999999") 
	if button_pressed:
		_fill_color = Color("FF0000")
	self.get("theme_override_styles/fill").set_bg_color(_fill_color)
		
