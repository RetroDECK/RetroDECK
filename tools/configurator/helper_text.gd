extends RichTextLabel

var selected_element

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get a reference to the helper_text node
	var helper_text_node = $bubble/helper_text
	
	# Ensure that the helper_text node exists before trying to access it
	if helper_text_node != null:
		# Set the text of the helper_text node only if the element is selected and has the 'description' variable
		if selected_element != null and selected_element.has("description"):
			helper_text_node.text = selected_element.description
		else:
			helper_text_node.text = ""
	else:
		print("Error: helper_text node not found!")
