extends Label

@onready var helper_text_node = self

func _ready():
	# Connect the signal that gets fired on every focus change
	get_viewport().connect("gui_focus_changed", _on_focus_changed)

func _on_focus_changed(selected_element:Control) -> void:
	if selected_element != null and selected_element.has_meta("rekku"):
		#helper_text_node.text = selected_element.get_meta("rekku")
		%pop_rtl.visible = true
		%pop_rtl.text = selected_element.get_meta("rekku")
