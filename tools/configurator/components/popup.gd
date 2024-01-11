extends Control

var content = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if (content != null):
		$Panel/VBoxContainer/ContentContainer.add_child(content)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_content(new_content):
	content = load(new_content).instantiate()

func _on_back_pressed():
	queue_free()
